function ui = createFileSelectionPanel(parent, labels, callbacks, opts)
%CREATEFILESELECTIONPANEL Create a shared file-action panel with a listbox.
%
% Usage:
%   labels = struct('panelTitle','Files','openFiles','Open file(s)');
%   callbacks = struct('onOpenFiles',@onOpen,'onExport',@onExport);
%   ui = labkit.ui.createFileSelectionPanel(parent, labels, callbacks);
%
% Inputs:
%   parent - parent grid.
%   labels - optional struct of visible text labels.
%   callbacks - optional struct of button/listbox callbacks.
%   opts - optional struct.
%
% Label fields:
%   panelTitle, openFiles, openFolder, removeSelected, clearAll, export,
%   loadedText.
%
% Callback fields:
%   onOpenFiles, onOpenFolder, onRemoveSelected, onClearAll, onExport,
%   onSelectFile.
%
% Options:
%   showRemoveSelected - logical, default true when onRemoveSelected exists.
%   multiselect - "off" (default) or "on" for the listbox.
%   row - logical parent row, default 1.
%
% Output:
%   ui - struct with panel, grid, buttons, listbox, and loadedText fields.

    if nargin < 4
        opts = struct();
    end

    showRemoveSelected = optionValue(opts, 'showRemoveSelected', ...
        isfield(callbacks, 'onRemoveSelected'));
    multiselect = optionValue(opts, 'multiselect', 'off');
    row = optionValue(opts, 'row', 1);

    gridOpts = struct( ...
        'rowHeight', {{'fit', '1x', 'fit'}}, ...
        'columnWidth', {{'1x'}}, ...
        'columnSpacing', 0);
    ui = labkit.ui.createPanelGrid( ...
        parent, labelValue(labels, 'panelTitle', 'Files'), row, [3 1], gridOpts);

    if showRemoveSelected
        ui.buttonGrid = uigridlayout(ui.grid, [3 2]);
        ui.buttonGrid.RowHeight = {'fit', 'fit', 'fit'};
    else
        ui.buttonGrid = uigridlayout(ui.grid, [2 2]);
        ui.buttonGrid.RowHeight = {'fit', 'fit'};
    end
    ui.buttonGrid.Layout.Row = 1;
    ui.buttonGrid.Layout.Column = 1;
    ui.buttonGrid.ColumnWidth = {'1x', '1x'};
    ui.buttonGrid.RowSpacing = 8;
    ui.buttonGrid.ColumnSpacing = 8;
    ui.buttonGrid.Padding = [0 0 0 0];

    ui.openButton = uibutton(ui.buttonGrid, ...
        'Text', labelValue(labels, 'openFiles', 'Open file(s)'), ...
        'ButtonPushedFcn', callbackValue(callbacks, 'onOpenFiles'));
    ui.openButton.Layout.Row = 1;
    ui.openButton.Layout.Column = 1;

    ui.openFolderButton = uibutton(ui.buttonGrid, ...
        'Text', labelValue(labels, 'openFolder', 'Open folder'), ...
        'ButtonPushedFcn', callbackValue(callbacks, 'onOpenFolder'));
    ui.openFolderButton.Layout.Row = 1;
    ui.openFolderButton.Layout.Column = 2;

    if showRemoveSelected
        ui.removeButton = uibutton(ui.buttonGrid, ...
            'Text', labelValue(labels, 'removeSelected', 'Remove selected'), ...
            'ButtonPushedFcn', callbackValue(callbacks, 'onRemoveSelected'));
        ui.removeButton.Layout.Row = 2;
        ui.removeButton.Layout.Column = 1;

        ui.clearButton = uibutton(ui.buttonGrid, ...
            'Text', labelValue(labels, 'clearAll', 'Clear all'), ...
            'ButtonPushedFcn', callbackValue(callbacks, 'onClearAll'));
        ui.clearButton.Layout.Row = 2;
        ui.clearButton.Layout.Column = 2;

        ui.exportButton = uibutton(ui.buttonGrid, ...
            'Text', labelValue(labels, 'export', 'Export'), ...
            'ButtonPushedFcn', callbackValue(callbacks, 'onExport'));
        ui.exportButton.Layout.Row = 3;
        ui.exportButton.Layout.Column = [1 2];
    else
        ui.clearButton = uibutton(ui.buttonGrid, ...
            'Text', labelValue(labels, 'clearAll', 'Clear all'), ...
            'ButtonPushedFcn', callbackValue(callbacks, 'onClearAll'));
        ui.clearButton.Layout.Row = 2;
        ui.clearButton.Layout.Column = 1;

        ui.exportButton = uibutton(ui.buttonGrid, ...
            'Text', labelValue(labels, 'export', 'Export'), ...
            'ButtonPushedFcn', callbackValue(callbacks, 'onExport'));
        ui.exportButton.Layout.Row = 2;
        ui.exportButton.Layout.Column = 2;
    end

    ui.listbox = uilistbox(ui.grid, ...
        'Items', {}, ...
        'Multiselect', multiselect, ...
        'ValueChangedFcn', callbackValue(callbacks, 'onSelectFile'));
    ui.listbox.Layout.Row = 2;
    ui.listbox.Layout.Column = 1;

    ui.loadedText = uieditfield(ui.grid, 'text', ...
        'Editable', 'off', ...
        'Value', labelValue(labels, 'loadedText', 'No files loaded'));
    ui.loadedText.Layout.Row = 3;
    ui.loadedText.Layout.Column = 1;
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isfield(opts, name)
        value = opts.(name);
    end
end

function value = labelValue(labels, name, defaultValue)
    value = defaultValue;
    if isfield(labels, name)
        value = labels.(name);
    end
end

function cb = callbackValue(callbacks, name)
    cb = [];
    if isfield(callbacks, name)
        cb = callbacks.(name);
    end
end
