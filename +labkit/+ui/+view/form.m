function varargout = form(parent, spec)
%FORM Create LabKit form controls from a unified control spec.
%
% Usage:
%   [lbl, spinner] = labkit.ui.view.form(parent, struct( ...
%       'kind', 'spinner', 'label', 'Samples:', ...
%       'value', 10, 'limits', [1 Inf], 'step', 1, ...
%       'callback', @onChanged));
%
%   ui = labkit.ui.view.form(parent, struct( ...
%       'title', 'Settings', 'row', 2, 'layout', [2 2], ...
%       'controls', [struct('id','mode','kind','dropdown', ...)]));
%
% Inputs:
%   parent - parent grid or shell tab grid.
%   spec - scalar struct. Single-control specs use kind/label fields. Section
%       specs use title, row, layout, and controls fields.
%
% Control fields:
%   id - optional valid field name for returned ui.controls.(id).
%   kind - "spinner", "dropdown", "edit", "readonly", "info", "button",
%       or "checkbox".
%   label - label text for labeled controls.
%   style - edit-field style, default "text".
%   value, items, limits, step, valueDisplayFormat, enabled, callback -
%       optional common values.
%   text - button or checkbox label text.
%   row, column - optional layout location.
%
% Outputs:
%   Single-control call returns [labelHandle, controlHandle] for labeled
%   controls or the control handle for button/checkbox/readonly without a
%   label. Section calls return a struct with panel, grid, controls,
%   labels, setValue, and getValue.
%
% setValue(id, value, reason) no-ops when the value is unchanged and
% suppresses app-facing semantic callbacks for "internal" updates.

    if nargin < 2
        error('labkit:ui:view:InvalidFormSpec', ...
            'form requires a scalar struct spec.');
    end

    if ~isstruct(spec) || ~isscalar(spec)
        error('labkit:ui:view:InvalidFormSpec', ...
            'form requires a scalar struct spec.');
    end

    if isfield(spec, 'controls')
        ui = createFormSection(parent, spec);
        varargout = {ui};
        return;
    end

    [labelHandle, controlHandle] = createOne(parent, spec);
    if nargout <= 1
        varargout = {controlHandle};
    elseif isfield(spec, 'kind') && strcmpi(char(string(spec.kind)), 'info')
        varargout = {controlHandle, labelHandle};
    else
        varargout = {labelHandle, controlHandle};
    end
end

function ui = createFormSection(parent, spec)
    layout = optionValue(spec, 'layout', [numel(spec.controls) 2]);
    ui = labkit.ui.view.section(parent, ...
        optionValue(spec, 'title', ''), ...
        optionValue(spec, 'row', []), ...
        layout, optionValue(spec, 'sectionOptions', struct()));
    ui.controls = struct();
    ui.labels = struct();
    ui.setValue = @setValue;
    ui.getValue = @getValue;

    controls = spec.controls;
    for k = 1:numel(controls)
        controlSpec = controls(k);
        if ~isfield(controlSpec, 'row')
            controlSpec.row = k;
        end
        [lbl, ctrl] = createOne(ui.grid, controlSpec);
        if isfield(controlSpec, 'id') && strlength(string(controlSpec.id)) > 0
            id = matlab.lang.makeValidName(char(string(controlSpec.id)));
            ui.controls.(id) = ctrl;
            if ~isempty(lbl)
                ui.labels.(id) = lbl;
            end
        end
    end

    function setValue(id, value, reason)
        if nargin < 3
            reason = "programmatic";
        end
        name = matlab.lang.makeValidName(char(string(id)));
        if ~isfield(ui.controls, name)
            error('labkit:ui:view:UnknownControl', ...
                'Unknown form control "%s".', char(string(id)));
        end
        ctrl = ui.controls.(name);
        if ~isprop(ctrl, 'Value') || valuesEqual(ctrl.Value, value)
            return;
        end
        oldCallback = callbackProperty(ctrl);
        cleanupObj = suppressCallback(ctrl, oldCallback, reason); %#ok<NASGU>
        ctrl.Value = value;
    end

    function value = getValue(id)
        name = matlab.lang.makeValidName(char(string(id)));
        if ~isfield(ui.controls, name)
            error('labkit:ui:view:UnknownControl', ...
                'Unknown form control "%s".', char(string(id)));
        end
        ctrl = ui.controls.(name);
        if isprop(ctrl, 'Value')
            value = ctrl.Value;
        else
            value = [];
        end
    end
end

function [lbl, ctrl] = createOne(parent, spec)
    kind = lower(char(string(optionValue(spec, 'kind', 'edit'))));
    labelText = char(string(optionValue(spec, 'label', '')));
    args = commonArgs(spec);

    switch kind
        case 'spinner'
            [lbl, ctrl] = createLabeledSpinner(parent, labelText, args{:});
        case 'dropdown'
            [lbl, ctrl] = createLabeledDropdown(parent, labelText, args{:});
        case 'edit'
            style = optionValue(spec, 'style', 'text');
            [lbl, ctrl] = createLabeledEditField(parent, labelText, style, args{:});
        case 'readonly'
            lbl = [];
            ctrl = createReadOnlyTextField(parent, args{:});
        case 'info'
            row = optionValue(spec, 'row', []);
            [ctrl, lbl] = createReadOnlyInfoRow(parent, row, labelText);
        case 'button'
            lbl = [];
            ctrl = uibutton(parent, args{:});
            if isfield(spec, 'text')
                ctrl.Text = spec.text;
            elseif isfield(spec, 'label')
                ctrl.Text = spec.label;
            end
        case 'checkbox'
            lbl = [];
            ctrl = uicheckbox(parent, args{:});
            if isfield(spec, 'text')
                ctrl.Text = spec.text;
            elseif isfield(spec, 'label')
                ctrl.Text = spec.label;
            end
        otherwise
            error('labkit:ui:view:UnknownControlKind', ...
                'Unsupported form control kind "%s".', kind);
    end

    if isfield(spec, 'row') && ~isempty(spec.row)
        placeHandle(lbl, spec.row, 1);
        if strcmp(kind, 'button') || strcmp(kind, 'checkbox') || strcmp(kind, 'readonly')
            placeHandle(ctrl, spec.row, optionValue(spec, 'column', [1 2]));
        else
            placeHandle(ctrl, spec.row, optionValue(spec, 'column', 2));
        end
    end
end

function args = commonArgs(spec)
    args = {};
    if isfield(spec, 'items')
        args = [args, {'Items', spec.items}];
    end
    if isfield(spec, 'value')
        args = [args, {'Value', spec.value}];
    end
    if isfield(spec, 'limits')
        args = [args, {'Limits', spec.limits}];
    end
    if isfield(spec, 'step')
        args = [args, {'Step', spec.step}];
    end
    if isfield(spec, 'valueDisplayFormat')
        args = [args, {'ValueDisplayFormat', spec.valueDisplayFormat}];
    end
    if isfield(spec, 'enabled')
        args = [args, {'Enable', onOff(spec.enabled)}];
    end
    if isfield(spec, 'callback')
        if any(strcmpi(char(string(optionValue(spec, 'kind', 'edit'))), ...
                {'button'}))
            args = [args, {'ButtonPushedFcn', spec.callback}];
        else
            args = [args, {'ValueChangedFcn', spec.callback}];
        end
    end
end

function placeHandle(h, row, column)
    if isempty(h) || ~isvalid(h)
        return;
    end
    h.Layout.Row = row;
    h.Layout.Column = column;
end

function oldCallback = callbackProperty(ctrl)
    oldCallback = struct('property', '', 'value', []);
    for prop = {'ValueChangedFcn', 'ButtonPushedFcn'}
        name = prop{1};
        if isprop(ctrl, name)
            oldCallback.property = name;
            oldCallback.value = ctrl.(name);
            return;
        end
    end
end

function cleanupObj = suppressCallback(ctrl, oldCallback, reason)
    if strcmp(string(reason), "user") || isempty(oldCallback.property)
        cleanupObj = onCleanup(@() []);
        return;
    end
    ctrl.(oldCallback.property) = [];
    cleanupObj = onCleanup(@() restoreCallback(ctrl, oldCallback));
end

function restoreCallback(ctrl, oldCallback)
    if ~isempty(ctrl) && isvalid(ctrl) && isprop(ctrl, oldCallback.property)
        ctrl.(oldCallback.property) = oldCallback.value;
    end
end

function tf = valuesEqual(a, b)
    try
        tf = isequaln(a, b);
    catch
        tf = false;
    end
end

function text = onOff(value)
    if islogical(value) && isscalar(value)
        if value
            text = 'on';
        else
            text = 'off';
        end
    else
        text = char(string(value));
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end
