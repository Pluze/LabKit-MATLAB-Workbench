function ui = createFilePanel(parent, exportText, callbacks)
%CREATEFILEPANEL Create the shared multi-file control panel.

    ui = struct();
    ui.panel = uipanel(parent, 'Title', 'Files');
    ui.panel.Layout.Row = 1;

    ui.grid = uigridlayout(ui.panel, [4 2]);
    ui.grid.RowHeight = {'fit', 'fit', 'fit', 'fit'};
    ui.grid.ColumnWidth = {'1x', '1x'};
    ui.grid.Padding = [8 8 8 8];
    ui.grid.RowSpacing = 8;
    ui.grid.ColumnSpacing = 8;

    ui.openButton = uibutton(ui.grid, ...
        'Text', 'Open DTA file(s)', ...
        'ButtonPushedFcn', callbacks.onOpenFiles);
    ui.openButton.Layout.Row = 1;
    ui.openButton.Layout.Column = [1 2];

    ui.openFolderButton = uibutton(ui.grid, ...
        'Text', 'Open folder recursively', ...
        'ButtonPushedFcn', callbacks.onOpenFolder);
    ui.openFolderButton.Layout.Row = 2;
    ui.openFolderButton.Layout.Column = [1 2];

    ui.removeButton = uibutton(ui.grid, ...
        'Text', 'Remove selected', ...
        'ButtonPushedFcn', callbacks.onRemoveSelected);
    ui.removeButton.Layout.Row = 3;
    ui.removeButton.Layout.Column = 1;

    ui.clearButton = uibutton(ui.grid, ...
        'Text', 'Clear all', ...
        'ButtonPushedFcn', callbacks.onClearAll);
    ui.clearButton.Layout.Row = 3;
    ui.clearButton.Layout.Column = 2;

    ui.exportButton = uibutton(ui.grid, ...
        'Text', exportText, ...
        'ButtonPushedFcn', callbacks.onExport);
    ui.exportButton.Layout.Row = 4;
    ui.exportButton.Layout.Column = [1 2];
end
