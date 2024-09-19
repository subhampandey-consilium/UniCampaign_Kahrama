/// <reference path="definitions/jquery.d.ts" />
/// <reference path="definitions/underscore.d.ts" />
var FormForm = (function () {
    function FormForm(dom, fields) {
        this.dom = dom;
        this.fields = fields;
        this.col1 = 4;
        this.col2 = 8;
        this.isHorizontal = dom.hasClass('form-horizontal') || dom.hasClass('form-horizantal');
    }
    /**
     * Render the Form and attach it to the DOM.
     */
    FormForm.prototype.render = function () {
        this._renderFields();
        this._renderButtons();
    };
    /**
     * Render all buttons and attach them to the DOM.
     * @private
     */
    FormForm.prototype._renderButtons = function () {
        var renderedButtons = '';
        _.each(this.fields, function (field) {
            if (!_.contains(['button', 'submit'], field.type))
                return;
            renderedButtons += FormForm.templates.button(field);
        });
        if (this.isHorizontal) {
            renderedButtons = FormForm.templates.horizontalOffsetGroup({
                renderedData: renderedButtons,
                col1: this.col1,
                col2: this.col2
            });
        }
        this.dom.append(renderedButtons);
    };
    /**
     * Render all form-fields and attach them to the DOM.
     * @private
     */
    FormForm.prototype._renderFields = function () {
        var _this = this;
        _.each(this.fields, function (field) {
            var formField, inputTemplate, inputGroupTemplate, groupTemplate, typeConfig, select2cfg;
            // skip buttons
            if (_.contains(['button', 'submit'], field.type))
                return;
            typeConfig = FormForm.typeConfig[field.type];
            if (!field.id)
                field.id = _.uniqueId('formform');
            inputTemplate = _this._getInputTemplate(field);
            inputGroupTemplate = _this._getInputGroupTemplate(field);
            groupTemplate = _this._getGroupTemplate(field);
            formField = $(groupTemplate({
                field: field,
                renderedData: inputGroupTemplate({
                    field: field,
                    renderedData: inputTemplate(field)
                }),
                col1: _this.col1,
                col2: _this.col2
            }));
            // Select-Optionen Rendern
            if (field.choices)
                _this._renderChoices(formField, field);
            // Initialen Wert setzten
            if (_.has(field, 'value') && typeConfig.value) {
                formField.find('input, select, textarea').val(field.value);
            }
            _this.dom.append(formField);
            if (typeConfig.select2) {
                select2cfg = { theme: 'bootstrap' };
                if (_.has(field, 'placeholder'))
                    select2cfg.placeholder = field.placeholder;
                formField.find('select').select2(select2cfg);
            }
            if (typeConfig.bootstrapMarkdown) {
                formField.find('textarea').markdown();
            }
        });
    };
    /**
     * Get the matching template for a form-field.
     */
    FormForm.prototype._getInputTemplate = function (field) {
        if (FormForm.typeConfig[field.type]) {
            return FormForm.typeConfig[field.type].template;
        }
        throw 'Unkown field type: ' + field.type;
    };
    FormForm.prototype._getInputGroupTemplate = function (field) {
        if (field.addonPrepend || field.addonAppend) {
            return FormForm.templates.inputGroup;
        }
        else {
            return function (field) {
                return field.renderedData;
            };
        }
    };
    /**
     * Get the matching template for a form-group.
     */
    FormForm.prototype._getGroupTemplate = function (field) {
        if (field.type == 'checkboxinput' && this.isHorizontal) {
            return FormForm.templates.horizontalOffsetGroup;
        }
        else if (_.contains(['checkboxinput', 'hidden'], field.type)) {
            // no form-group
            return function (data) {
                return data.renderedData;
            };
        }
        else if (this.isHorizontal) {
            return FormForm.templates.horizontalGroup;
        }
        else {
            return FormForm.templates.group;
        }
    };
    /*
     * Render options for a select-box
     */
    FormForm.prototype._renderChoices = function (formField, field) {
        var select, choices;
        choices = field.choices;
        if (!_.isArray(choices) || !choices.length)
            return;
        select = formField.find('select');
        if (_.isArray(choices[0][1])) {
            select.html(FormForm.templates.optGroups(choices));
        }
        else {
            select.html(FormForm.templates.options(choices));
        }
    };
    /**
     * Get the field config object by name.
     */
    FormForm.prototype.getFieldByName = function (name) {
        return _.find(this.fields, function (field) {
            return field.name == name;
        });
    };
    /*
     * Reset the form to default values.
     */
    FormForm.prototype.reset = function () {
    };
    /*
     * Setze alle Formularfelder auf die Werte aus dem Objekt.
     */
    FormForm.prototype.update = function (obj) {
    };
    FormForm.templates = {
        group: _.template('<div class="form-group">\
				<label for="<%= data.id %>"><%- data.field.label %></label>\
				<%= data.renderedData %>\
				<span class="help-block"><%- data.field.helpText %></span>\
			</div>', { variable: 'data' }),
        inputGroup: _.template('<div class="input-group">\
				<% if (data.field.addonPrepend) { %>\
					<div class="input-group-addon"><%- data.field.addonPrepend %></div>\
				<% } %>\
				<%= data.renderedData %>\
				<% if (data.field.addonAppend) { %>\
					<div class="input-group-addon"><%- data.field.addonAppend %></div>\
				<% } %>\
			</div>', { variable: 'data' }),
        horizontalGroup: _.template('<div class="form-group">\
				<label class="col-sm-<%= data.col1 %> control-label" for="<%= data.id %>"><%- data.field.label %> <span class="error inline"><%- data.field.required?"*":"" %></span></label>\
				<div class="col-sm-<%= data.col2 %>">\
					<%= data.renderedData %>\
				</div>\
				<div class="col-sm-<%= data.col1 %>"></div>\
				<div class="col-sm-<%= data.col2 %>">\
					<span class="help-block" style="margin: 0"><%- data.field.helpText %></span>\
				</div>\
				<div class="clearfix"></div>\
			</div>', { variable: 'data' }),
        horizontalOffsetGroup: _.template('<div class="form-group">\
				<div class="col-sm-offset-<%= data.col1 %> col-sm-<%= data.col2 %>">\
					<%= data.renderedData %>\
				</div>\
			</div>', { variable: 'data' }),
        select: _.template('<select name="<%= data.name %>" class="form-control" id="<%= data.id %>"></select>', { variable: 'data' }),
        selectmultiple: _.template('<select multiple="multiple" class="form-control" name="<%= data.name %>" id="<%= data.id %>"></select>', { variable: 'data' }),
        input: _.template('<input type="<%= data.type %>" name="<%= data.name %>" class="form-control" id="<%= data.id %>"\
            <% if (data.value){ %>value="<%- data.value %>"<% } %> <% if (data.placeholder){ %>placeholder="<%- data.placeholder %>"<% } %> />', { variable: 'data' }),
        textarea: _.template('<textarea name="<%= data.name %>" class="form-control" id="<%= data.id %>" rows="4"></textarea>', { variable: 'data' }),
        file: _.template('<div class="controls" style="height: 34px;">\
				<div class="fileinput <% if (data.value) { %>fileinput-exists<% } else { %>fileinput-new<% } %>" data-provides="fileinput">\
					<input id="<%= data.id %>-clear_id" name="<%= data.name %>-clear" type="checkbox">\
					<div class="input-group">\
						<div class="form-control uneditable-input" data-trigger="fileinput">\
							<span class="fileinput-filename"><%- data.value %></span>\
						</div>\
						<span class="input-group-addon btn btn-grey btn-file">\
							<span class="fileinput-new">select File</span>\
							<span class="fileinput-exists">\
								<span class="glyphicon glyphicon-file" style="margin-right: 0"></span>\
							</span>\
							<input type="file" id="<%= data.id %>" name="<%= data.name %>">\
						</span>\
						<a href="#" class="input-group-addon btn btn-grey fileinput-exists" data-dismiss="fileinput">\
							<span class="glyphicon glyphicon-remove" style="margin-right: 0"></span>\
						</a>\
					</div>\
				</div>\
			</div>', { variable: 'data' }),
        options: _.template('<% _.each(choices, function(choice) { %>\
                <% if (_.isArray(choice))%>\
                <option value="<%= choice[0] %>"><%- choice[1]||choice[0] %></option>\
                <% else %>\
                <option value="<%= choice %>"><%- choice %></option>\
			<% }) %>', { variable: 'choices' }),
        optGroups: _.template('<% _.each(choices, function(optgroup) { %>\
				<optgroup label="<%- optgroup[0] %>">\
					<% _.each(optgroup[1], function(choice) { %>\
						<option value="<%= choice[0] %>"><%- choice[1] %></option>\
					<% }) %>\
				</optgroup>\
			<% }) %>', { variable: 'choices' }),
        checkbox: _.template('<div class="checkbox">\
				<label>\
					<input type="checkbox" name="<%= data.name %>" <% if (data.value){ %>checked="checked"<% } %>> <%- data.label %>\
				</label>\
			</div>', { variable: 'data' }),
        button: _.template('<button type="<%= data.type %>" class="btn <%= data.class %>">\
				<% if (data.icon) { %><span class="fa fa-<%= data.icon %>"></span><% } %>\
				<span><%- data.label %></span>\
			</button>', { variable: 'data' })
    };
    FormForm.typeConfig = {
        text: {
            template: FormForm.templates.input
        },
        password: {
            template: FormForm.templates.input
        },
        number: {
            template: FormForm.templates.input
        },
        hidden: {
            template: FormForm.templates.input
        },
        textarea: {
            template: FormForm.templates.textarea,
            value: true
        },
        checkboxinput: {
            template: FormForm.templates.checkbox
        },
        select: {
            template: FormForm.templates.select,
            value: true
        },
        selectmultiple: {
            template: FormForm.templates.selectmultiple,
            value: true
        },
        select2: {
            template: FormForm.templates.select,
            value: true,
            select2: true
        },
        selectmultiple2: {
            template: FormForm.templates.selectmultiple,
            value: true,
            select2: true
        },
        file: {
            template: FormForm.templates.file
        },
        button: {
            template: FormForm.templates.button
        },
        submit: {
            template: FormForm.templates.button
        },
        markdown: {
            template: FormForm.templates.textarea,
            value: true,
            bootstrapMarkdown: true
        }
    };
    return FormForm;
}());
//# sourceMappingURL=bootstrap-formform.js.map