% Private UI runtime helper. Expected caller: buildFilePanelControl. Inputs are a
% parent panel, filePanel props, and semantic callback wiring. Output contains
% the grid and child handles for a multi-file filePanel.
function parts = createMultiFilePanelParts(panel, props, callbacks)
    grid = createGrid(panel, props);
    emptyText = emptyFileText(props);
    chooseButton = createButton(grid, props, callbacks, ...
        'chooseLabel', 'Add...', 'choose', 'onChoose', 1);
    chooseButton.UserData = "file";
    chooseButton.Tooltip = ['Select one or more files from the same folder. ' ...
        'If MATLAB reports files from different folders, cancel the reopened dialog.'];
    folderButton = createButton(grid, props, callbacks, ...
        'folderLabel', 'Add folder', 'choose', 'onChoose', 2);
    folderButton.UserData = "folder";
    folderButton.Tooltip = 'Add supported files directly inside one folder.';
    recursiveFolderButton = createButton(grid, props, callbacks, ...
        'recursiveFolderLabel', 'Add folder tree', ...
        'choose', 'onChoose', 3);
    recursiveFolderButton.UserData = "recursiveFolder";
    recursiveFolderButton.Tooltip = ...
        'Add supported files from one folder and all of its subfolders.';
    removeButton = createButton(grid, props, callbacks, ...
        'removeLabel', 'Remove selected', 'remove', 'onRemove', [1 2]);
    removeButton.Layout.Row = 2;
    clearButton = createButton(grid, props, callbacks, ...
        'clearLabel', 'Clear', 'clear', 'onClear', 3);
    clearButton.Layout.Row = 2;
    listbox = createListbox(grid, props, callbacks, emptyText);
    status = createStatusBox(grid, props);
    parts = struct('grid', grid, ...
        'chooseButton', chooseButton, ...
        'folderButton', folderButton, ...
        'recursiveFolderButton', recursiveFolderButton, ...
        'removeButton', removeButton, ...
        'clearButton', clearButton, ...
        'listbox', listbox, ...
        'status', status);
end

function grid = createGrid(panel, props)
    if showStatus(props)
        grid = uigridlayout(panel, [4 3]);
        grid.RowHeight = {'fit', 'fit', '1x', 'fit'};
    else
        grid = uigridlayout(panel, [3 3]);
        grid.RowHeight = {'fit', 'fit', '1x'};
    end
    grid.ColumnWidth = {'1x', '1x', '1x'};
    grid.RowSpacing = 6;
    grid.ColumnSpacing = 8;
    grid.Padding = [8 8 8 8];
end

function button = createButton(grid, props, callbacks, ...
        labelProp, defaultLabel, callbackField, originalCallbackProp, column)
    button = uibutton(grid, ...
        'Text', optionValue(props, labelProp, defaultLabel), ...
        'ButtonPushedFcn', callbacks.(callbackField));
    applyTextFit(button, 'charsPerStep', 18, 'maxShrinkSteps', 3);
    callbacks.setOriginalCallbackName(button, optionValue(props, ...
        originalCallbackProp, []));
    button.Layout.Row = 1;
    button.Layout.Column = column;
end

function listbox = createListbox(grid, props, callbacks, emptyText)
    listbox = uilistbox(grid, 'Items', {emptyText}, ...
        'Multiselect', fileMultiselect(props));
    listbox.Value = initialListValue(listbox, emptyText);
    listbox.ValueChangedFcn = callbacks.selection;
    callbacks.setOriginalCallbackName(listbox, optionValue(props, ...
        'onSelectionChange', []));
    listbox.Layout.Row = 3;
    listbox.Layout.Column = [1 3];
end

function status = createStatusBox(grid, props)
    status = [];
    if ~showStatus(props)
        return;
    end
    status = uitextarea(grid, ...
        'Value', fileStatusText(props), ...
        'Editable', 'off', ...
        'Tag', 'LabKitFilePanelStatusText');
    applyTextFit(status);
    status.Layout.Row = 4;
    status.Layout.Column = [1 3];
end

function value = initialListValue(listbox, text)
    if strcmp(listbox.Multiselect, 'on')
        value = {text};
    else
        value = text;
    end
end

function mode = fileMultiselect(props)
    if strcmp(char(string(optionValue(props, 'selectionMode', 'single'))), 'multiple')
        mode = 'on';
    else
        mode = 'off';
    end
end

function text = fileStatusText(props)
    text = emptyFileText(props);
end

function text = emptyFileText(props)
    if isstruct(props) && isfield(props, 'emptyText')
        text = char(string(props.emptyText));
        return;
    end
    if isstruct(props) && isfield(props, 'status')
        text = char(string(props.status));
        return;
    end
    text = 'No files loaded';
end

function tf = showStatus(props)
    tf = true;
    if isstruct(props) && isfield(props, 'showStatus')
        tf = logical(props.showStatus);
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end
