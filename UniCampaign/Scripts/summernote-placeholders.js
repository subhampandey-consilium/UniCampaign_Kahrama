(function (factory) {
    if (typeof define === 'function' && define.amd) {
        define(['jquery'], factory);
    } else if (typeof module === 'object' && module.exports) {
        module.exports = factory(require('jquery'));
    } else {
        factory(window.jQuery);
    }
}
(function ($) {
    $.extend($.summernote.plugins, {
        'placeholders': function (context) {
            var self = this;
            var layoutInfo = context.layoutInfo;
            var $toolbar = layoutInfo.toolbar;
            var ui = $.summernote.ui;
            this.collection = [];
            this.insideJob = false;
            this.get = function () {
                var placeholdersFound = context.code().match(/{{placeholder_\d+}}/g);
                return _.filter(self.collection, function (item) {
                    return _.contains(placeholdersFound, '{{' + item.key + '}}');
                });
            };

            this.update = function (placeholders) {
                self.collection = _.filter(self.collection, function (item) {
                    return _.contains(placeholders, '{{' + item.key + '}}');
                });
            };

            this.initialize = function () {
            };

            this.events = {
                'summernote.change': function (e, data) {
                    if (!self.insideJob && $.summernote.dom.emptyPara != data) {
                        var placeholdersFound = context.code().match(/{{placeholder_\d+}}/g);
                        if (placeholdersFound != null) {
                            self.update(placeholdersFound);
                        }
                    }
                }
            };

            this.create = function (items) {
                self.destroy();
                self.collection = [];
                var $dropdown = ui.dropdown({
                    template: function (item) {
                        return item.text ? item.text : item;
                    },
                    items: items,
                    callback: function ($dropdown) {
                        $dropdown.css({ "overflow": 'auto', "max-height": '150px' });
                        $dropdown.on('click', 'li a', function (e) {
                            e.preventDefault();
                            var id = _.uniqueId('placeholder_');
                            self.insideJob = true;
                            context.invoke('editor.insertText', '{{' + id + '}}');
                            self.insideJob = false;
                            self.collection.push({ key: id, value: $(this).attr('data-value') });
                        });
                    }
                });
                var $button = ui.button({
                    className: '',
                    contents: 'Placeholder <i class="fa fa-caret-down"></i>',
                    data: {
                        toggle: 'dropdown'
                    }
                });
                var group = ui.buttonGroup([
                    $button, $dropdown
                ]);
                this.$dropdown = group.render();
                $toolbar.append(this.$dropdown);
            };

            this.destroy = function () {
                if (this.$dropdown) {
                    this.$dropdown.remove();
                    this.$dropdown = null;
                }
            };
        }
    });
}));
