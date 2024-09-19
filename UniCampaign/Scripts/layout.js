var globalNotification, keepAliveCounter = 0, grid;

var globalDateTimePickerIcons = {
    time: 'icon-clock',
    date: 'icon-calendar',
    up: 'icon-arrow-up',
    down: 'icon-arrow-down',
    previous: 'icon-arrow-left',
    next: 'icon-arrow-right',
    today: 'icon-target',
    clear: 'icon-trash',
    close: 'icon-close'
};

function reloadMainGrid() {
    try {
        if (grid !== undefined) {
            if (typeof grid.reload == 'function') {
                grid.reload();
            }
        }
    } catch (e) {
    }
}

function globalAjaxSuccessHandler(response) {
    console.log(response);
    $('#loader').hide();
    if ($('#modal_editor').hasClass('in')) {
        $('#modal_editor').modal('hide');
    }
    hideGlobalNotification();
    showGlobalNotification('success', response);
    reloadMainGrid();
}

function globalAjaxErrorHandler(jqXhr, error, description) {
    if (description != null && description != undefined && description.length > 0 && error !== 'abort') {
        hideGlobalNotification();
        showGlobalNotification('error', description);
    }
    $('#loader').hide();
}

function showModalEditor() {
    $('#modal_editor').modal('show');
    $('#loader').hide();
}


function hideGlobalNotification() {
    if (globalNotification != undefined) {
        globalNotification.remove();
    }
}

function showGlobalNotification(type, contents) {
    console.log(contents);
    var message = '', url = null;
    message = contents;
    if (typeof (contents) == 'object') {
        message = contents.message || '';
        url = contents.url || null;
    }
    else if (_.isString(contents) && contents.indexOf('{') >= 0 && contents.indexOf(':') > 1 && contents.indexOf('}') > 2) {
        contents = JSON.parse(contents);
        message = contents.message || '';
        url = contents.url || null;
    }
    var length = message !== null && message !== undefined ? message.length : 0;
    var options = {
        title: false,
        delay: 2000,
        delayIndicator: false,
        pauseDelayOnHover: true,
        continueDelayOnInactiveTab: false,
        closeOnClick: true,
        icon: false,
        closable: true,
        iconSource: false,
        sound: false,
        position: 'center top', //or 'center bottom'
        msg: message,
        messageHeight: length > 95 ? 90 : 60,
        size: length > 98 ? 'normal' : 'mini'
    };
    if (url != null) {
        options.onClick = function (e) {
            window.open(url, "_blank");
        }
        //options.onClickUrl = url;
    }
    globalNotification = Lobibox.notify(type || 'error', options);
}
var contactListUtil = {
    parseCondition: function ($condition) {
        var newCondition = {};
        newCondition.Attribute = $('.filter-condition-attribute', $condition).val();
        newCondition.OperatorType = $('.filter-condition-operator', $condition).val();
        if (newCondition.OperatorType == 0) {
            return null;
        }
        newCondition.Value = $('.filter-condition-value', $condition).val();
        return newCondition;
    },
    parseFilter: function ($filter) {
        var newFilter = {};
        newFilter.OperatorType = $('.filter-type', $filter).val();
        newFilter.Conditions = [];
        var conditionCollection = $('.filter-condition-collection > .filter-condition', $filter);
        for (var i = 0; i < conditionCollection.length; i++) {
            var theCondition = this.parseCondition($(conditionCollection[i]));
            if (theCondition)
                newFilter.Conditions.push(theCondition);
        }
        if (newFilter.Conditions.length == 0) {
            return null;
        }
        return newFilter;
    }
};
$(document).ready(function (e) {

    //Global AJAX Setup
    $.ajaxSetup({ global: true, cache: false, error: globalAjaxErrorHandler, complete: function () { keepAliveCounter = 0; } });

    /// Persistent Navigation 
    var path = $(location).attr('pathname').toLowerCase();
    $('#sidebar_navigation').find('.nav-item').each(function (idx, elem) {
        var is_current = false;
        $(this).find('a').each(function (idx, elem) {
            if ($(this).attr('href')) {
                var href = $(this).attr('href').toLowerCase();
                if (href == path) {
                    $(this).parent('li').addClass('active');
                    is_current = true;
                    return;
                }
            }
        });
        if (is_current) {
            $(this).addClass('active');
            $(this).find('.collapse').first().addClass('in');
        }
    });

    $(document).on('hidden.bs.modal', '#modal_editor', function (e) {
        $(this).empty();
        hideGlobalNotification();
    });

    ///UniCampaign Filter
    $(document).on('click', '.unicampaign-filter .filter-expression .btn-add-filter-condition', function (e) {
        debugger;
        var $parentElement = $(this).parentsUntil('.filter-expression').parent();
        console.log('Element', $parentElement);
        var $collectionElement = $('.filter-condition-collection', $parentElement);
        console.log('Condition', $collectionElement);
        var $allConditions = $('.filter-condition', $collectionElement);
        console.log('$allConditions', $allConditions);
        var numberOfConditions = $allConditions.length;
        console.log('numberOfConditions', numberOfConditions);
        if (numberOfConditions == 4) {
            return;
        }
        var $newCondition = $allConditions.first().clone(false);
        $('.btn-remove-filter-condition', $newCondition).removeClass('hidden');
        $('input', $newCondition).val('');
        $('select', $newCondition).prop('selectedIndex', 0);
        $collectionElement.append($newCondition);
        if (numberOfConditions == 3) {
            $(this).addClass('disabled');
        }
    });

    $(document).on('click', '.unicampaign-filter .filter-expression .btn-reset-filter', function (e) {
        var $parentElement = $(this).parentsUntil('.filter-expression').parent();
        console.log('Element', $parentElement);
        $('.filter-condition', $parentElement).not(":first").remove();
        $('input', $parentElement).val('');
        $('select', $parentElement).prop('selectedIndex', 0);
        $('.btn-add-filter-condition', $parentElement).removeClass('disabled');
    });

    $(document).on('click', '.unicampaign-filter .filter-expression .filter-condition-collection .filter-condition .btn-remove-filter-condition', function (e) {
        var $parentElement = $(this).parentsUntil('.filter-condition').parent();
        console.log('Element', $parentElement);
        var conditionElement = $(this).parentsUntil('.filter-condition').parent();
        console.log('Element', conditionElement);
        var numberOfConditions = $(conditionElement).parents('.filter-condition-collection').find('.filter-condition').length;
        if (numberOfConditions == 4) {
            $(conditionElement).parents('.filter-expression').find('.btn-add-filter-condition').first().removeClass('disabled');
        }
        conditionElement.remove();
    });

    $(document).on('click', '.unicampaign-filter .btn-add-filter', function (e) {
        var collectionElement = $(this).parentsUntil('.unicampaign-filter').parent().find('.filter-collection').first();
        var currentNumberOfFilters = collectionElement.find('.filter-expression').length;
        var filterNumber = parseInt(collectionElement.find('.filter-expression').last().attr('data-number')) + 1;
        var newFilterTitle = 'Filter_' + filterNumber;
        var newFilter = collectionElement.find('.filter-expression').first().clone();
        $(newFilter).find('.btn-remove-filter').first().removeClass('hidden');
        var newFilterId = newFilterTitle + _.uniqueId();
        $(newFilter).attr('id', newFilterId);
        $(newFilter).attr('data-number', filterNumber);
        $(newFilter).addClass('active in');
        $(collectionElement).find('.tab-pane').removeClass('active').removeClass('in');
        $(collectionElement).append(newFilter);
        $(newFilter).find('.btn-reset-filter').first().trigger('click');
        var numberOfFilters = collectionElement.find('.filter-expression').length;
        var filterTabCollection = $(this).parentsUntil('.unicampaign-filter').parent().find('.filter-tabs').first();
        filterTabCollection.find('li').removeClass('active');
        var newTab = filterTabCollection.find('li').first().clone(false);
        newTab.addClass('active');
        newTab.find('a').first().text(newFilterTitle);
        newTab.find('a').first().attr('href', '#' + newFilterId);
        filterTabCollection.append(newTab);
    });

    $(document).on('click', '.unicampaign-filter .filter-expression .btn-remove-filter', function (e) {
        var activeFilterElement = $(this).parentsUntil('.filter-expression').parent();
        var filterTabCollection = $(this).parentsUntil('.filter-collection').parent().siblings('.filter-tabs').first();
        var activeTabElement = filterTabCollection.find('li.active').first();
        var previousTabElement = activeTabElement.prev();
        activeFilterElement.remove();
        activeTabElement.remove();
        previousTabElement.children('a').first().trigger('click');
    });
});

