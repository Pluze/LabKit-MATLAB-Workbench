function ui = panel(parent, kind, varargin)
%PANEL Create a reusable view component group.
%
% App-facing contract:
%   ui = labkit.ui.view.panel(parent, kind, ...)
%   ui = labkit.ui.view.panel(parent, spec)
%
% Inputs:
%   parent - parent container for the component group. For top/bottom plot
%            controls this is the top controls panel.
%   kind - component kind: "files", "log", "text", "table", or
%          "topBottomPlotControls".
%   spec - optional struct alternative with kind plus fields matching the
%          positional arguments described below.
%
% Positional forms:
%   panel(parent, "files", labels, callbacks, opts)
%   panel(parent, "log", row, initialValue)
%   panel(parent, "text", title, row, lines, opts)
%   panel(parent, "table", title, row, columnNames, initialData)
%   panel(topPanel, "topBottomPlotControls", bottomPanel, xItems, yItems,
%       topDefaults, bottomDefaults, valueChangedFcn)
%
% Output:
%   ui - struct of MATLAB component handles owned by the created component.

    if isstruct(kind)
        ui = panelFromSpec(parent, kind);
        return;
    end

    switch normalizeKind(kind)
        case 'files'
            labels = positional(varargin, 1, struct());
            callbacks = positional(varargin, 2, struct());
            opts = positional(varargin, 3, struct());
            ui = fileSelectionPanel(parent, labels, callbacks, opts);
        case 'log'
            row = positional(varargin, 1, 1);
            initialValue = positional(varargin, 2, {'GUI started.'});
            ui = logPanel(parent, row, initialValue);
        case 'text'
            titleText = positional(varargin, 1, '');
            row = positional(varargin, 2, 1);
            lines = positional(varargin, 3, {});
            opts = positional(varargin, 4, struct());
            ui = textPanel(parent, titleText, row, lines, opts);
        case 'table'
            titleText = positional(varargin, 1, '');
            row = positional(varargin, 2, 1);
            columnNames = positional(varargin, 3, {});
            initialData = positional(varargin, 4, cell(0, numel(columnNames)));
            ui = resultTable(parent, titleText, row, columnNames, initialData);
        case 'topbottomplotcontrols'
            bottomPanel = positional(varargin, 1, []);
            xItems = positional(varargin, 2, {});
            yItems = positional(varargin, 3, {});
            topDefaults = positional(varargin, 4, struct());
            bottomDefaults = positional(varargin, 5, struct());
            valueChangedFcn = positional(varargin, 6, []);
            ui = topBottomPlotControls(parent, bottomPanel, xItems, yItems, ...
                topDefaults, bottomDefaults, valueChangedFcn);
        otherwise
            error('labkit_ui:panel:UnknownKind', ...
                'Unknown LabKit view panel kind "%s".', char(kind));
    end
end

function ui = panelFromSpec(parent, spec)
    kind = requireField(spec, 'kind');
    switch normalizeKind(kind)
        case 'files'
            labels = fieldOr(spec, 'labels', struct());
            callbacks = fieldOr(spec, 'callbacks', struct());
            opts = mergeFieldOptions(fieldOr(spec, 'options', struct()), spec, {'row'});
            ui = fileSelectionPanel(parent, labels, callbacks, opts);
        case 'log'
            ui = logPanel(parent, fieldOr(spec, 'row', 1), ...
                fieldOr(spec, 'initialValue', {'GUI started.'}));
        case 'text'
            ui = textPanel(parent, fieldOr(spec, 'title', ''), ...
                fieldOr(spec, 'row', 1), fieldOr(spec, 'lines', {}), ...
                fieldOr(spec, 'options', struct()));
        case 'table'
            columnNames = fieldOr(spec, 'columnNames', {});
            ui = resultTable(parent, fieldOr(spec, 'title', ''), ...
                fieldOr(spec, 'row', 1), columnNames, ...
                fieldOr(spec, 'initialData', cell(0, numel(columnNames))));
        case 'topbottomplotcontrols'
            ui = topBottomPlotControls(parent, requireField(spec, 'bottomPanel'), ...
                fieldOr(spec, 'xItems', {}), fieldOr(spec, 'yItems', {}), ...
                fieldOr(spec, 'topDefaults', struct()), ...
                fieldOr(spec, 'bottomDefaults', struct()), ...
                fieldOr(spec, 'callback', []));
        otherwise
            error('labkit_ui:panel:UnknownKind', ...
                'Unknown LabKit view panel kind "%s".', char(kind));
    end
end

function key = normalizeKind(kind)
    key = lower(regexprep(char(string(kind)), '[^a-zA-Z0-9]', ''));
end

function value = positional(args, index, defaultValue)
    value = defaultValue;
    if numel(args) >= index && ~isempty(args{index})
        value = args{index};
    end
end

function value = fieldOr(spec, name, defaultValue)
    value = defaultValue;
    if isfield(spec, name) && ~isempty(spec.(name))
        value = spec.(name);
    end
end

function value = requireField(spec, name)
    if ~isfield(spec, name) || isempty(spec.(name))
        error('labkit_ui:panel:MissingField', ...
            'labkit.ui.view.panel spec requires field "%s".', name);
    end
    value = spec.(name);
end

function opts = mergeFieldOptions(opts, spec, names)
    for k = 1:numel(names)
        name = names{k};
        if isfield(spec, name) && ~isempty(spec.(name))
            opts.(name) = spec.(name);
        end
    end
end
