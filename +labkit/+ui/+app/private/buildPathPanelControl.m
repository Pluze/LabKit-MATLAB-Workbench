% Private UI app helper. Expected caller: buildControl pathPanel branch.
% Inputs are one validated pathPanel spec, parent grid, target row, and
% callback wiring functions. Output is the semantic pathPanel adapter.
% Side effects: creates MATLAB UI controls and may open chooser dialogs
% through the adapter's choosePaths callback.
function adapter = buildPathPanelControl(pathSpec, parentGrid, row, callbacks)
    props = pathSpec.props;
    panel = uipanel(parentGrid, 'Title', optionValue(props, 'label', pathSpec.id));
    panel.Layout.Row = row;
    panel.Layout.Column = [1 2];
    grid = uigridlayout(panel, [3 2]);
    grid.RowHeight = {'fit', '1x', 'fit'};
    grid.ColumnWidth = {'1x', '1x'};
    grid.RowSpacing = 6;
    grid.ColumnSpacing = 8;
    grid.Padding = [8 8 8 8];

    chooseButton = uibutton(grid, 'Text', chooseButtonText(props), ...
        'ButtonPushedFcn', callbacks.choose);
    callbacks.setOriginalCallbackName(chooseButton, optionValue(props, ...
        'onChoose', []));
    chooseButton.Layout.Row = 1;
    chooseButton.Layout.Column = 1;

    clearButton = uibutton(grid, 'Text', optionValue(props, 'clearLabel', ...
        'Clear'), 'ButtonPushedFcn', callbacks.clear);
    callbacks.setOriginalCallbackName(clearButton, optionValue(props, ...
        'onClear', []));
    clearButton.Layout.Row = 1;
    clearButton.Layout.Column = 2;

    emptyText = emptyPathText(props);
    listbox = uilistbox(grid, 'Items', {emptyText}, ...
        'Multiselect', pathMultiselect(props));
    if strcmp(listbox.Multiselect, 'on')
        listbox.Value = {emptyText};
    else
        listbox.Value = emptyText;
    end
    listbox.ValueChangedFcn = callbacks.selection;
    callbacks.setOriginalCallbackName(listbox, optionValue(props, ...
        'onSelectionChange', []));
    listbox.Layout.Row = 2;
    listbox.Layout.Column = [1 2];

    status = uieditfield(grid, 'text', 'Editable', 'off', ...
        'Value', pathStatusText(props, {}));
    status.Layout.Row = 3;
    status.Layout.Column = [1 2];

    adapter = struct();
    adapter.id = pathSpec.id;
    adapter.kind = 'pathPanel';
    adapter.spec = pathSpec;
    adapter.props = props;
    adapter.panel = panel;
    adapter.grid = grid;
    adapter.chooseButton = chooseButton;
    adapter.clearButton = clearButton;
    adapter.listbox = listbox;
    adapter.status = status;
    adapter.valueHandle = listbox;
    adapter.getValue = @() currentPathValues(adapter);
    adapter.setValue = @(paths) applyPathSelection(adapter, paths, true);
    adapter.currentValue = @() currentPathValues(adapter);
    adapter.applySelection = @applyPathSelection;
    adapter.choosePaths = @() choosePaths(adapter);
    adapter.normalizePathList = @normalizePathList;
end

function control = applyPathSelection(control, paths, updateStatus)
    items = normalizedPaths(paths);
    emptyText = emptyPathText(control.props);
    if isempty(items)
        control.listbox.Items = {emptyText};
        if strcmp(control.listbox.Multiselect, 'on')
            control.listbox.Value = {emptyText};
        else
            control.listbox.Value = emptyText;
        end
    else
        control.listbox.Items = items;
        if strcmp(control.listbox.Multiselect, 'on')
            control.listbox.Value = items;
        else
            control.listbox.Value = items{1};
        end
    end
    if updateStatus
        control.status.Value = pathStatusText(control.props, items);
    end
end

function paths = choosePaths(control)
    props = control.props;
    if isfield(props, 'dialogProvider') && isa(props.dialogProvider, 'function_handle')
        paths = normalizedPaths(props.dialogProvider(props));
        return;
    end

    mode = optionValue(props, 'mode', 'singleFile');
    switch mode
        case 'singleFile'
            paths = chooseFiles(props, false);
        case 'multiFile'
            paths = chooseFiles(props, true);
        case {'folder', 'outputFolder'}
            paths = chooseFolder(optionValue(props, 'startPath', pwd));
        case 'multiFolder'
            paths = chooseMultipleFolders(optionValue(props, 'startPath', pwd));
        otherwise
            error('labkit:ui:app:InvalidPathMode', ...
                'Unsupported pathPanel mode "%s".', mode);
    end
end

function paths = chooseFiles(props, allowMulti)
    if ~canOpenBlockingDialog()
        paths = {};
        return;
    end
    filters = normalizeFileFilters(optionValue(props, 'filters', ...
        {'*.*', 'All files'}));
    titleText = optionValue(props, 'dialogTitle', chooseButtonText(props));
    startPath = optionValue(props, 'startPath', pwd);
    if allowMulti
        [files, folder] = uigetfile(filters, titleText, startPath, ...
            'MultiSelect', 'on');
    else
        [files, folder] = uigetfile(filters, titleText, startPath);
    end
    if isequal(files, 0) || isequal(folder, 0)
        paths = {};
        return;
    end
    if ischar(files) || isstring(files)
        files = {char(string(files))};
    end
    files = reshape(files, 1, []);
    paths = cell(1, numel(files));
    for k = 1:numel(files)
        paths{k} = fullfile(folder, char(string(files{k})));
    end
end

function paths = chooseFolder(startPath)
    if ~canOpenBlockingDialog()
        paths = {};
        return;
    end
    folder = uigetdir(startPath, 'Choose folder');
    if isequal(folder, 0)
        paths = {};
    else
        paths = {folder};
    end
end

function paths = chooseMultipleFolders(startPath)
    if ~canOpenBlockingDialog()
        return;
    end
    paths = {};
    nextPath = startPath;
    while true
        folder = uigetdir(nextPath, sprintf('Choose folder %d', numel(paths) + 1));
        if isequal(folder, 0)
            break;
        end
        paths{end + 1} = folder;
        nextPath = folder;
        choice = questdlg('Add another folder?', 'Select folders', ...
            'Add another', 'Done', 'Done');
        if ~strcmp(choice, 'Add another')
            break;
        end
    end
    paths = unique(paths, 'stable');
end

function tf = canOpenBlockingDialog()
    tf = usejava('desktop') && desktop('-inuse');
end

function paths = normalizedPaths(paths)
    paths = cellstr(normalizePathList(paths).');
end

function values = currentPathValues(control)
    values = strings(0, 1);
    if isfield(control, 'listbox') && isvalid(control.listbox)
        emptyText = emptyPathText(control.props);
        isEmptyPrompt = isempty(control.listbox.Items) || ...
            (numel(control.listbox.Items) == 1 && ...
            strcmp(control.listbox.Items{1}, emptyText));
        if ~isEmptyPrompt
            values = normalizePathList(control.listbox.Value);
        end
    end
end

function paths = normalizePathList(value)
    if isempty(value)
        paths = strings(0, 1);
    elseif ischar(value)
        paths = string({value});
    elseif isstring(value)
        paths = value;
    elseif iscell(value)
        if ~all(cellfun(@isTextScalar, value))
            error('labkit:ui:app:InvalidPathList', ...
                'Path panel values must be text scalars.');
        end
        paths = string(value);
    else
        error('labkit:ui:app:InvalidPathList', ...
            'Path panel values must be char, string, or a cell array of text.');
    end
    paths = paths(:);
    paths = paths(strlength(paths) > 0);
end

function text = pathStatusText(props, paths)
    if isempty(paths)
        text = emptyStatusText(props);
    elseif numel(paths) == 1
        text = char(string(paths{1}));
    else
        text = sprintf('%d selected', numel(paths));
    end
end

function text = emptyStatusText(props)
    if isstruct(props) && isfield(props, 'status')
        text = char(string(props.status));
    else
        text = emptyPathText(props);
    end
end

function text = emptyPathText(props)
    if isstruct(props) && isfield(props, 'emptyText')
        text = char(string(props.emptyText));
        return;
    end
    if isstruct(props) && isfield(props, 'status')
        text = char(string(props.status));
        return;
    end

    mode = char(string(optionValue(props, 'mode', 'singleFile')));
    switch mode
        case 'multiFile'
            text = 'No files selected';
        case {'folder', 'multiFolder'}
            text = 'No folder selected';
        case 'outputFolder'
            text = 'No output folder selected';
        otherwise
            text = 'No file selected';
    end
end

function text = chooseButtonText(props)
    if isfield(props, 'chooseLabel')
        text = char(string(props.chooseLabel));
        return;
    end

    mode = optionValue(props, 'mode', 'singleFile');
    switch mode
        case {'folder', 'multiFolder', 'outputFolder'}
            text = 'Choose folder';
        otherwise
            text = 'Choose files';
    end
end

function value = pathMultiselect(props)
    mode = optionValue(props, 'selectionMode', defaultSelectionMode( ...
        optionValue(props, 'mode', 'singleFile')));
    if strcmp(mode, 'multiple')
        value = 'on';
    else
        value = 'off';
    end
end

function mode = defaultSelectionMode(pathMode)
    if any(strcmp(pathMode, {'multiFile', 'multiFolder'}))
        mode = 'multiple';
    else
        mode = 'single';
    end
end

function filters = normalizeFileFilters(filters)
    if iscell(filters) && numel(filters) == 1 && iscell(filters{1})
        filters = filters{1};
    end
    if ischar(filters)
        return;
    end
    if isstring(filters)
        if isscalar(filters)
            filters = char(filters);
            return;
        end
        filters = cellstr(filters);
    end
    if iscell(filters)
        filters = cellfun(@(value) char(string(value)), filters, ...
            'UniformOutput', false);
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end

function tf = isTextScalar(value)
    tf = (ischar(value) && (isrow(value) || isempty(value))) || ...
        (isstring(value) && isscalar(value));
end
