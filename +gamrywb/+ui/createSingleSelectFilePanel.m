function ui = createSingleSelectFilePanel(parent, exportText, callbacks)
%CREATESINGLESELECTFILEPANEL Create the shared single-select files panel.

    ui = struct();
    ui.panel = uipanel(parent, 'Title', 'Files');
    ui.panel.Layout.Row = 1;

    ui.grid = uigridlayout(ui.panel, [3 1]);
    ui.grid.RowHeight = {'fit', '1x', 'fit'};
    ui.grid.ColumnWidth = {'1x'};
    ui.grid.Padding = [8 8 8 8];
    ui.grid.RowSpacing = 8;
    ui.grid.ColumnSpacing = 0;

    ui.buttonGrid = uigridlayout(ui.grid, [2 2]);
    ui.buttonGrid.Layout.Row = 1;
    ui.buttonGrid.Layout.Column = 1;
    ui.buttonGrid.RowHeight = {'fit', 'fit'};
    ui.buttonGrid.ColumnWidth = {'1x', '1x'};
    ui.buttonGrid.RowSpacing = 8;
    ui.buttonGrid.ColumnSpacing = 8;
    ui.buttonGrid.Padding = [0 0 0 0];

    ui.openButton = uibutton(ui.buttonGrid, ...
        'Text', 'Open DTA file(s)', ...
        'ButtonPushedFcn', callbacks.onOpenFiles);
    ui.openButton.Layout.Row = 1;
    ui.openButton.Layout.Column = 1;

    ui.openFolderButton = uibutton(ui.buttonGrid, ...
        'Text', 'Open folder recursively', ...
        'ButtonPushedFcn', callbacks.onOpenFolder);
    ui.openFolderButton.Layout.Row = 1;
    ui.openFolderButton.Layout.Column = 2;

    ui.clearButton = uibutton(ui.buttonGrid, ...
        'Text', 'Clear all', ...
        'ButtonPushedFcn', callbacks.onClearAll);
    ui.clearButton.Layout.Row = 2;
    ui.clearButton.Layout.Column = 1;

    ui.exportButton = uibutton(ui.buttonGrid, ...
        'Text', exportText, ...
        'ButtonPushedFcn', callbacks.onExport);
    ui.exportButton.Layout.Row = 2;
    ui.exportButton.Layout.Column = 2;

    ui.listbox = uilistbox(ui.grid, ...
        'Items', {}, ...
        'Multiselect', 'off', ...
        'ValueChangedFcn', callbacks.onSelectFile);
    ui.listbox.Layout.Row = 2;
    ui.listbox.Layout.Column = 1;

    ui.loadedText = uieditfield(ui.grid, 'text', ...
        'Editable', 'off', ...
        'Value', 'No files loaded');
    ui.loadedText.Layout.Row = 3;
    ui.loadedText.Layout.Column = 1;
end
