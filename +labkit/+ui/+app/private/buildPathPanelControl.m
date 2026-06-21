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
    storePathItems(listbox, strings(0, 1));
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
    adapter.currentItems = @() currentPathItems(adapter);
    adapter.setSelection = @setCurrentSelection;
    adapter.applySelection = @applyPathSelection;
    adapter.choosePaths = @(varargin) choosePaths(currentControl(adapter, varargin{:}));
    adapter.normalizePathList = @normalizePathList;
end

function control = applyPathSelection(control, paths, updateStatus)
    items = normalizedPaths(paths);
    storePathItems(control.listbox, string(items(:)));
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

function control = setCurrentSelection(control, paths)
    selection = normalizedPaths(paths);
    if isempty(selection) || isempty(control.listbox.Items)
        return;
    end
    if strcmp(control.listbox.Multiselect, 'on')
        valid = selection(ismember(selection, string(control.listbox.Items)));
        if ~isempty(valid)
            control.listbox.Value = cellstr(valid(:).');
        end
    else
        first = char(selection(1));
        if any(strcmp(control.listbox.Items, first))
            control.listbox.Value = first;
        end
    end
end

function paths = choosePaths(control)
    props = control.props;
    if isfield(props, 'dialogProvider') && isa(props.dialogProvider, 'function_handle')
        paths = expandPathChoices(normalizedPaths(props.dialogProvider(props)), props);
        return;
    end

    mode = optionValue(props, 'mode', 'singleFile');
    switch mode
        case 'singleFile'
            paths = chooseFiles(props, false);
        case 'multiFile'
            paths = chooseFileOrFolder(props);
        case {'folder', 'outputFolder'}
            paths = chooseFolder(optionValue(props, 'startPath', pwd));
        case 'multiFolder'
            paths = chooseMultipleFolders(optionValue(props, 'startPath', pwd));
        otherwise
            error('labkit:ui:app:InvalidPathMode', ...
                'Unsupported pathPanel mode "%s".', mode);
    end
end

function control = currentControl(defaultControl, varargin)
    control = defaultControl;
    if ~isempty(varargin)
        control = varargin{1};
    end
end

function paths = chooseFiles(props, allowMulti)
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
    paths = strings(numel(files), 1);
    for k = 1:numel(files)
        paths(k) = string(fullfile(folder, char(string(files{k}))));
    end
    paths = expandPathChoices(paths, props);
end

function paths = chooseFileOrFolder(props)
    startPath = optionValue(props, 'startPath', pwd);
    choice = questdlg('Choose files or recursively load a folder?', ...
        'Choose input source', 'File', 'Folder', 'Cancel', 'File');
    switch choice
        case 'File'
            paths = chooseFiles(props, false);
        case 'Folder'
            folder = chooseFolder(startPath);
            paths = expandPathChoices(string(folder(:)), props);
        otherwise
            paths = strings(0, 1);
    end
end

function paths = chooseFolder(startPath)
    folder = uigetdir(startPath, 'Choose folder');
    if isequal(folder, 0)
        paths = {};
    else
        paths = {folder};
    end
end

function paths = chooseMultipleFolders(startPath)
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
            storedPaths = currentPathItems(control);
            visibleItems = string(control.listbox.Items(:));
            if numel(storedPaths) == numel(visibleItems)
                [matched, indices] = ismember(values, visibleItems);
                if all(matched)
                    values = storedPaths(indices);
                end
            end
        end
    end
end

function values = currentPathItems(control)
    values = strings(0, 1);
    if isfield(control, 'listbox') && isvalid(control.listbox)
        try
            values = string(getappdata(control.listbox, 'labkitPathPanelPaths'));
            values = values(:);
            values = values(strlength(values) > 0);
        catch
            values = strings(0, 1);
        end
    end
end

function storePathItems(listbox, paths)
    try
        setappdata(listbox, 'labkitPathPanelPaths', string(paths(:)));
    catch
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

function paths = expandPathChoices(paths, props)
    paths = normalizePathList(paths);
    if isempty(paths) || ~strcmp(optionValue(props, 'mode', ''), 'multiFile')
        return;
    end

    filters = normalizeFileFilters(optionValue(props, 'filters', ...
        {'*.*', 'All files'}));
    expanded = strings(0, 1);
    for k = 1:numel(paths)
        path = paths(k);
        if isfolder(path)
            expanded = [expanded; filesUnderFolder(path, filters)];
        else
            expanded(end + 1, 1) = path;
        end
    end
    paths = unique(expanded, 'stable');
end

function paths = filesUnderFolder(folder, filters)
    patterns = fileFilterPatterns(filters);
    paths = strings(0, 1);
    for k = 1:numel(patterns)
        entries = dir(fullfile(char(folder), '**', char(patterns(k))));
        entries = entries(~[entries.isdir]);
        for iEntry = 1:numel(entries)
            paths(end + 1, 1) = string(fullfile(entries(iEntry).folder, entries(iEntry).name));
        end
    end
    paths = sort(unique(paths, 'stable'));
end

function patterns = fileFilterPatterns(filters)
    if ischar(filters) || isstring(filters)
        raw = string(filters);
    elseif iscell(filters)
        raw = string(filters(:, 1));
    else
        raw = "*.*";
    end

    patterns = strings(0, 1);
    for k = 1:numel(raw)
        tokens = split(raw(k), ';');
        tokens = strtrim(tokens);
        tokens = tokens(strlength(tokens) > 0);
        patterns = [patterns; tokens(:)];
    end
    if isempty(patterns)
        patterns = "*.*";
    end
    patterns = unique(patterns, 'stable');
    concretePatterns = patterns(patterns ~= "*.*" & patterns ~= "*");
    if ~isempty(concretePatterns)
        patterns = concretePatterns;
    end
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
