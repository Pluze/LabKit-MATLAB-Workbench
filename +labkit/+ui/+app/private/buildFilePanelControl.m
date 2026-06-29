% Private UI app helper. Expected caller: buildControl filePanel branch.
% Inputs are one validated filePanel spec, parent grid, target row, and
% callback wiring functions. Output is the semantic filePanel adapter.
% Side effects: creates MATLAB UI controls and may open chooser dialogs.
function adapter = buildFilePanelControl(fileSpec, parentGrid, row, callbacks)
    props = fileSpec.props;
    if isSingleMode(props)
        adapter = buildSingleFilePanelControl(fileSpec, parentGrid, row, callbacks);
    else
        adapter = buildMultiFilePanelControl(fileSpec, parentGrid, row, callbacks);
    end
end

function adapter = buildMultiFilePanelControl(fileSpec, parentGrid, row, callbacks)
    props = fileSpec.props;
    panel = uipanel(parentGrid, 'Title', optionValue(props, 'label', fileSpec.id));
    panel.Layout.Row = row;
    panel.Layout.Column = [1 2];
    grid = uigridlayout(panel, [3 3]);
    grid.RowHeight = {'fit', '1x', 'fit'};
    grid.ColumnWidth = {'1x', '1x', '1x'};
    grid.RowSpacing = 6;
    grid.ColumnSpacing = 8;
    grid.Padding = [8 8 8 8];

    chooseButton = uibutton(grid, ...
        'Text', optionValue(props, 'chooseLabel', 'Add...'), ...
        'ButtonPushedFcn', callbacks.choose);
    applyTextFit(chooseButton, 'charsPerStep', 18, 'maxShrinkSteps', 3);
    callbacks.setOriginalCallbackName(chooseButton, optionValue(props, ...
        'onChoose', []));
    chooseButton.Layout.Row = 1;
    chooseButton.Layout.Column = 1;

    removeButton = uibutton(grid, ...
        'Text', optionValue(props, 'removeLabel', 'Remove selected'), ...
        'ButtonPushedFcn', callbacks.remove);
    applyTextFit(removeButton, 'charsPerStep', 18, 'maxShrinkSteps', 3);
    callbacks.setOriginalCallbackName(removeButton, optionValue(props, ...
        'onRemove', []));
    removeButton.Layout.Row = 1;
    removeButton.Layout.Column = 2;

    clearButton = uibutton(grid, ...
        'Text', optionValue(props, 'clearLabel', 'Clear'), ...
        'ButtonPushedFcn', callbacks.clear);
    applyTextFit(clearButton, 'charsPerStep', 18, 'maxShrinkSteps', 3);
    callbacks.setOriginalCallbackName(clearButton, optionValue(props, ...
        'onClear', []));
    clearButton.Layout.Row = 1;
    clearButton.Layout.Column = 3;

    emptyText = emptyFileText(props);
    listbox = uilistbox(grid, 'Items', {emptyText}, ...
        'Multiselect', fileMultiselect(props));
    listbox.Value = initialListValue(listbox, emptyText);
    listbox.ValueChangedFcn = callbacks.selection;
    callbacks.setOriginalCallbackName(listbox, optionValue(props, ...
        'onSelectionChange', []));
    listbox.Layout.Row = 2;
    listbox.Layout.Column = [1 3];

    status = uitextarea(grid, ...
        'Value', fileStatusText(props, emptyFiles()), ...
        'Editable', 'off', ...
        'Tag', 'LabKitFilePanelStatusText');
    applyTextFit(status);
    status.Layout.Row = 3;
    status.Layout.Column = [1 3];

    adapter = baseFilePanelAdapter(fileSpec, props, panel, grid, callbacks);
    adapter.chooseButton = chooseButton;
    adapter.removeButton = removeButton;
    adapter.clearButton = clearButton;
    adapter.listbox = listbox;
    adapter.status = status;
    adapter.valueHandle = listbox;
    adapter.storageHandle = listbox;
    adapter = attachFilePanelMethods(adapter);

    storeFiles(adapter, emptyFiles());
end

function adapter = buildSingleFilePanelControl(fileSpec, parentGrid, row, callbacks)
    props = fileSpec.props;
    panel = uipanel(parentGrid, 'Title', optionValue(props, 'label', fileSpec.id));
    panel.Layout.Row = row;
    panel.Layout.Column = [1 2];
    grid = uigridlayout(panel, [1 2]);
    grid.RowHeight = {'fit'};
    grid.ColumnWidth = {'fit', '1x'};
    grid.RowSpacing = 6;
    grid.ColumnSpacing = 8;
    grid.Padding = [8 8 8 8];

    chooseButton = uibutton(grid, ...
        'Text', optionValue(props, 'chooseLabel', 'Choose...'), ...
        'ButtonPushedFcn', callbacks.choose);
    applyTextFit(chooseButton, 'charsPerStep', 18, 'maxShrinkSteps', 3);
    callbacks.setOriginalCallbackName(chooseButton, optionValue(props, ...
        'onChoose', []));
    chooseButton.Layout.Row = 1;
    chooseButton.Layout.Column = 1;

    displayField = uitextarea(grid, ...
        'Value', emptyFileText(props), ...
        'Editable', 'off', ...
        'Tag', 'LabKitFilePanelStatusText');
    applyTextFit(displayField);
    displayField.Layout.Row = 1;
    displayField.Layout.Column = 2;

    adapter = baseFilePanelAdapter(fileSpec, props, panel, grid, callbacks);
    adapter.chooseButton = chooseButton;
    adapter.status = displayField;
    adapter.displayField = displayField;
    adapter.valueHandle = displayField;
    adapter.storageHandle = displayField;
    adapter = attachFilePanelMethods(adapter);

    storeFiles(adapter, emptyFiles());
end

function adapter = baseFilePanelAdapter(fileSpec, props, panel, grid, callbacks)
    adapter = struct();
    adapter.id = fileSpec.id;
    adapter.kind = 'filePanel';
    adapter.spec = fileSpec;
    adapter.props = props;
    adapter.panel = panel;
    adapter.grid = grid;
    adapter.trace = optionValue(callbacks, 'trace', []);
end

function adapter = attachFilePanelMethods(adapter)
    adapter.getValue = @() currentSelectedFiles(adapter);
    adapter.setValue = @(paths) applyFileSelection(adapter, paths, true);
    adapter.currentValue = @() currentSelectedFiles(adapter);
    adapter.currentFiles = @() currentFiles(adapter);
    adapter.currentSelectedFiles = @() currentSelectedFiles(adapter);
    adapter.setFileSelection = @setCurrentFileSelection;
    adapter.applySelection = @applyFileSelection;
    adapter.appendSelection = @appendFileSelection;
    adapter.removeSelection = @removeCurrentSelection;
    adapter.choosePaths = @(varargin) chooseFilePaths(currentControl(adapter, varargin{:}));
    adapter.normalizePathList = @filePanelNormalizePathList;
    adapter.normalizeFiles = @normalizeFiles;
end

function value = initialListValue(listbox, text)
    if strcmp(listbox.Multiselect, 'on')
        value = {text};
    else
        value = text;
    end
end

function control = applyFileSelection(control, pathsOrFiles, updateStatus)
    files = normalizeFiles(pathsOrFiles);
    files = enforceMaxFiles(files, control.props);
    files = assignFileIds(files, 0);
    files = completeFileEntries(files);
    storeFiles(control, files);

    emptyText = emptyFileText(control.props);
    if isSingleMode(control.props)
        if isempty(files)
            setText(control.displayField, emptyText);
        else
            setText(control.displayField, char(files(1).displayName));
        end
        return;
    end

    labels = fileLabels(files);
    if isempty(files)
        control.listbox.Items = {emptyText};
        control.listbox.Value = initialListValue(control.listbox, emptyText);
    else
        control.listbox.Items = labels;
        if strcmp(control.listbox.Multiselect, 'on')
            control.listbox.Value = labels;
        else
            control.listbox.Value = labels{1};
        end
    end
    if updateStatus
        setText(control.status, fileStatusText(control.props, files));
    end
end

function [control, addedFiles] = appendFileSelection(control, pathsOrFiles)
    existingFiles = currentFiles(control);
    newFiles = normalizeFiles(pathsOrFiles);
    if isempty(newFiles)
        addedFiles = emptyFiles();
        return;
    end

    maxFiles = double(optionValue(control.props, 'maxFiles', Inf));
    if isSingleMode(control.props) || (isfinite(maxFiles) && maxFiles == 1)
        combinedFiles = newFiles(1);
        addedStart = 1;
    elseif isempty(existingFiles)
        combinedFiles = newFiles(:);
        addedStart = 1;
    else
        combinedFiles = [existingFiles; newFiles(:)];
        addedStart = numel(existingFiles) + 1;
    end

    combinedFiles = enforceMaxFiles(combinedFiles, control.props);
    combinedFiles = assignFileIds(combinedFiles, 0);
    combinedFiles = completeFileEntries(combinedFiles);
    if addedStart > numel(combinedFiles)
        addedFiles = emptyFiles();
    else
        addedFiles = combinedFiles(addedStart:end);
    end
    control = applyFileSelection(control, combinedFiles, true);
end

function control = setCurrentFileSelection(control, filesOrIds)
    files = currentFiles(control);
    if isempty(files) || isSingleMode(control.props)
        return;
    end
    if isstruct(filesOrIds)
        ids = fileIds(filesOrIds);
    else
        ids = string(filesOrIds);
        ids = ids(:);
    end
    ids = ids(strlength(ids) > 0);
    if isempty(ids)
        return;
    end
    labels = fileLabels(files);
    selected = labels(ismember(fileIds(files), ids));
    if isempty(selected)
        return;
    end
    if strcmp(control.listbox.Multiselect, 'on')
        control.listbox.Value = selected(:).';
    else
        control.listbox.Value = selected{1};
    end
end

function [control, removedFiles] = removeCurrentSelection(control)
    files = currentFiles(control);
    removedFiles = emptyFiles();
    if isempty(files)
        return;
    end
    if isSingleMode(control.props)
        removedFiles = files;
        control = applyFileSelection(control, emptyFiles(), true);
        return;
    end
    labels = string(fileLabels(files));
    selected = string(control.listbox.Value);
    removeMask = ismember(labels, selected(:));
    removedFiles = files(removeMask);
    files = files(~removeMask);
    control = applyFileSelection(control, files, true);
end

function paths = chooseFilePaths(control)
    props = control.props;
    if isfield(props, 'dialogProvider') && isa(props.dialogProvider, 'function_handle')
        traceFilePanelControl(control, 'dialog provider start', 'source=custom');
        paths = filePanelNormalizePathList(props.dialogProvider(props));
        traceFilePanelControl(control, 'dialog provider end', sprintf('count=%d', numel(paths)));
        if isSingleMode(props)
            if ~isempty(paths)
                paths = paths(1);
            end
        else
            paths = expandFileChoices(paths, props, control);
        end
        return;
    end

    startPath = labkit.ui.app.defaultDialogFolder("input", ...
        optionValue(props, 'startPath', ""));
    if isSingleMode(props)
        traceFilePanelControl(control, 'file chooser start', 'mode=single');
        paths = chooseFiles(props, startPath);
        traceFilePanelControl(control, 'file chooser end', sprintf('count=%d', numel(paths)));
        if ~isempty(paths)
            paths = paths(1);
        end
        return;
    end

    choice = questdlg('Add files or recursively load a folder?', ...
        'Add files', 'Files', 'Folder', 'Cancel', 'Files');
    switch choice
        case 'Files'
            traceFilePanelControl(control, 'file chooser start', 'mode=multi');
            paths = chooseFiles(props, startPath);
            traceFilePanelControl(control, 'file chooser end', sprintf('count=%d', numel(paths)));
        case 'Folder'
            folder = chooseFolder(startPath);
            paths = expandFileChoices(string(folder), props, control);
        otherwise
            paths = strings(0, 1);
    end
end

function paths = chooseFiles(props, startPath)
    filters = normalizeFilePanelFilters(optionValue(props, 'filters', {'*.*', 'All files'}));
    titleText = optionValue(props, 'dialogTitle', optionValue(props, 'chooseLabel', 'Choose files'));
    allowMulti = ~isSingleMode(props) && ...
        (isinf(double(optionValue(props, 'maxFiles', Inf))) || ...
        double(optionValue(props, 'maxFiles', Inf)) > 1);
    if allowMulti
        [files, folder] = uigetfile(filters, titleText, startPath, 'MultiSelect', 'on');
    else
        [files, folder] = uigetfile(filters, titleText, startPath);
    end
    if isequal(files, 0) || isequal(folder, 0)
        paths = strings(0, 1);
        return;
    end
    rememberDialogFolder(folder);
    if ischar(files) || isstring(files)
        files = {char(string(files))};
    end
    paths = strings(numel(files), 1);
    for k = 1:numel(files)
        paths(k) = string(fullfile(folder, char(string(files{k}))));
    end
end

function folder = chooseFolder(startPath)
    folder = uigetdir(startPath, 'Choose folder');
    if isequal(folder, 0)
        folder = strings(0, 1);
    else
        rememberDialogFolder(folder);
    end
end

function paths = expandFileChoices(paths, props, control)
    paths = filePanelNormalizePathList(paths);
    if isempty(paths)
        return;
    end
    filters = normalizeFilePanelFilters(optionValue(props, 'filters', {'*.*', 'All files'}));
    traceFilePanelControl(control, 'expand choices start', sprintf('count=%d', numel(paths)));
    expandedParts = cell(numel(paths), 1);
    for k = 1:numel(paths)
        path = paths(k);
        if isfolder(path)
            traceFilePanelControl(control, 'folder scan start', sprintf('index=%d', k));
            folderPaths = filesUnderFolder(path, filters);
            traceFilePanelControl(control, 'folder scan end', sprintf( ...
                'index=%d count=%d', k, numel(folderPaths)));
            if shouldRejectLargeFolder(folderPaths, path, props, control)
                traceFilePanelControl(control, 'folder scan rejected', sprintf( ...
                    'index=%d count=%d', k, numel(folderPaths)));
                folderPaths = strings(0, 1);
            end
            expandedParts{k} = folderPaths;
        else
            expandedParts{k} = path;
        end
    end
    paths = vertcat(expandedParts{:});
    traceFilePanelControl(control, 'expand choices end', sprintf('count=%d', numel(paths)));
end

function tf = shouldRejectLargeFolder(paths, folder, props, control)
    threshold = double(optionValue(props, 'folderWarningThreshold', 500));
    tf = false;
    if numel(paths) <= threshold
        return;
    end
    traceFilePanelControl(control, 'large folder prompt', sprintf( ...
        'count=%d threshold=%d', numel(paths), threshold));
    if isfield(props, 'folderWarningProvider') && isa(props.folderWarningProvider, 'function_handle')
        tf = ~logical(props.folderWarningProvider(folder, numel(paths), threshold));
        return;
    end
    message = sprintf(['Recursive scan found %d matching file(s) under:\n%s\n\n' ...
        'Loading a very large folder may take a while. Continue?'], ...
        numel(paths), char(folder));
    try
        fig = ancestor(control.panel, 'figure');
        answer = uiconfirm(fig, message, 'Large folder scan', ...
            'Options', {'Continue', 'Cancel'}, ...
            'DefaultOption', 'Cancel', ...
            'CancelOption', 'Cancel');
    catch
        answer = questdlg(message, 'Large folder scan', ...
            'Continue', 'Cancel', 'Cancel');
    end
    tf = ~strcmp(answer, 'Continue');
end

function paths = filesUnderFolder(folder, filters)
    patterns = filePanelFilterPatterns(filters);
    pathParts = cell(numel(patterns), 1);
    for k = 1:numel(patterns)
        entries = dir(fullfile(char(folder), '**', char(patterns(k))));
        entries = entries(~[entries.isdir]);
        patternPaths = strings(numel(entries), 1);
        for iEntry = 1:numel(entries)
            patternPaths(iEntry) = string(fullfile(entries(iEntry).folder, entries(iEntry).name));
        end
        pathParts{k} = patternPaths;
    end
    paths = vertcat(pathParts{:});
    paths = sort(unique(paths, 'stable'));
end

function labels = fileLabels(files)
    if isempty(files)
        labels = {};
        return;
    end
    paths = string({files.path}).';
    status = strings(numel(files), 1);
    for k = 1:numel(files)
        if isfield(files(k), 'status')
            status(k) = string(files(k).status);
        end
    end
    labels = labkit.ui.view.fileLabels(paths, 'status', status);
end

function files = normalizeFiles(value)
    if isempty(value)
        files = emptyFiles();
        return;
    end
    if isstruct(value) && all(isfield(value, {'path'}))
        files = value(:);
        files = assignFileIds(files, 0);
        files = completeFileEntries(files);
        return;
    end
    paths = filePanelNormalizePathList(value);
    files = repmat(emptyFile(), numel(paths), 1);
    for k = 1:numel(paths)
        files(k).path = paths(k);
        files(k).status = "";
    end
    files = completeFileEntries(files);
end

function files = completeFileEntries(files)
    for k = 1:numel(files)
        pathValue = "";
        if isfield(files(k), 'path')
            pathValue = filePanelScalarText(files(k).path, "");
        end
        files(k).path = pathValue;
        [~, base, ext] = fileparts(char(pathValue));
        name = string([base ext]);
        if strlength(name) == 0
            name = pathValue;
        end
        files(k).name = name;
        displayName = "";
        if isfield(files(k), 'displayName')
            displayName = filePanelScalarText(files(k).displayName, "");
        end
        if strlength(displayName) == 0
            files(k).displayName = name;
        else
            files(k).displayName = displayName;
        end
        if ~isfield(files(k), 'status')
            files(k).status = "";
        else
            files(k).status = filePanelScalarText(files(k).status, "");
        end
    end
end

function files = assignFileIds(files, offset)
    seen = strings(numel(files), 1);
    for k = 1:numel(files)
        id = "";
        if isfield(files(k), 'id')
            id = filePanelScalarText(files(k).id, "");
        end
        usedIds = seen(1:k-1);
        if strlength(id) == 0 || any(usedIds == id)
            idNumber = offset + k;
            candidate = "file" + string(idNumber);
            while any(usedIds == candidate)
                idNumber = idNumber + 1;
                candidate = "file" + string(idNumber);
            end
            files(k).id = candidate;
        end
        files(k).index = offset + k;
        seen(k) = string(files(k).id);
    end
end

function ids = fileIds(files)
    ids = strings(numel(files), 1);
    for k = 1:numel(files)
        if isfield(files(k), 'id')
            ids(k) = string(files(k).id);
        end
    end
end

function file = emptyFile()
    file = struct('id', "", 'index', 0, 'path', "", ...
        'name', "", 'displayName', "", 'status', "");
end

function files = emptyFiles()
    files = repmat(emptyFile(), 0, 1);
end

function files = enforceMaxFiles(files, props)
    if isSingleMode(props)
        maxFiles = 1;
    else
        maxFiles = double(optionValue(props, 'maxFiles', Inf));
    end
    if isfinite(maxFiles) && numel(files) > maxFiles
        files = files(1:maxFiles);
    end
end

function files = currentSelectedFiles(control)
    allFiles = currentFiles(control);
    files = emptyFiles();
    if isempty(allFiles)
        return;
    end
    if isSingleMode(control.props)
        files = allFiles;
        return;
    end
    labels = string(control.listbox.Items(:));
    selected = string(control.listbox.Value);
    if numel(labels) ~= numel(allFiles)
        labels = string(fileLabels(allFiles));
    end
    [matched, idx] = ismember(selected(:), labels);
    if any(matched)
        files = allFiles(idx(matched));
    end
end

function files = currentFiles(control)
    files = emptyFiles();
    if isfield(control, 'storageHandle') && isvalid(control.storageHandle)
        try
            files = getappdata(control.storageHandle, 'labkitFilePanelFiles');
            files = files(:);
        catch
            files = emptyFiles();
        end
    end
end

function storeFiles(control, files)
    try
        setappdata(control.storageHandle, 'labkitFilePanelFiles', files(:));
    catch
    end
end

function control = currentControl(defaultControl, varargin)
    control = defaultControl;
    if ~isempty(varargin)
        control = varargin{1};
    end
end

function text = fileStatusText(props, files)
    if isempty(files)
        text = emptyStatusText(props);
    elseif numel(files) == 1
        text = '1 file';
    else
        text = sprintf('%d files', numel(files));
    end
end

function text = emptyStatusText(props)
    if isstruct(props) && isfield(props, 'status')
        text = char(string(props.status));
    else
        text = emptyFileText(props);
    end
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

function setText(handle, text)
    if isprop(handle, 'Text')
        handle.Text = char(string(text));
        applyTextFit(handle);
    elseif isprop(handle, 'Value')
        handle.Value = char(string(text));
        applyTextFit(handle);
    end
end

function value = fileMultiselect(props)
    mode = optionValue(props, 'selectionMode', 'single');
    if strcmp(mode, 'multiple')
        value = 'on';
    else
        value = 'off';
    end
end

function tf = isSingleMode(props)
    tf = strcmp(char(string(optionValue(props, 'mode', 'multi'))), 'single');
end

function rememberDialogFolder(folder)
    try
        setpref('LabKit', 'LastInputFolder', char(string(folder)));
    catch
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end
