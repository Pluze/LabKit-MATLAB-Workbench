% Private UI view helper. Expected caller: setFileSelection.
% Inputs are the current UI registry and a filePanel id. Side effects are
% figure appdata/title updates and previewArea axes title refreshes.
function applySelectedFileContext(ui, id)
    if ~(isstruct(ui) && isfield(ui, 'figure') && isfield(ui, 'controls'))
        return;
    end

    fig = ui.figure;
    if isempty(fig) || ~isvalid(fig)
        return;
    end

    control = resolveControl(ui, id);
    context = selectedFileContext(control);
    setappdata(fig, 'labkitSelectedFileContext', context);
    refreshFigureTitle(fig, context);
    refreshPreviewTitles(ui);
end

function context = selectedFileContext(control)
    context = struct( ...
        'valid', false, ...
        'filePanelId', string(control.id), ...
        'index', 0, ...
        'count', 0, ...
        'name', "");
    if ~isfield(control, 'currentFiles') || ~isa(control.currentFiles, 'function_handle') || ...
            ~isfield(control, 'currentSelectedFiles') || ~isa(control.currentSelectedFiles, 'function_handle')
        return;
    end

    files = control.currentFiles();
    selected = control.currentSelectedFiles();
    if isempty(files) || isempty(selected)
        return;
    end

    chosen = selected(1);
    context.count = numel(files);
    context.index = selectedIndex(files, chosen);
    context.name = selectedName(chosen);
    context.valid = context.index > 0 && context.count > 0 && ...
        strlength(context.name) > 0;
end

function index = selectedIndex(files, chosen)
    index = 0;
    if isfield(chosen, 'index')
        value = double(chosen.index);
        if isscalar(value) && isfinite(value) && value > 0
            index = value;
            return;
        end
    end
    if isfield(chosen, 'id') && isfield(files, 'id')
        ids = string({files.id});
        match = find(ids == string(chosen.id), 1, 'first');
        if ~isempty(match)
            index = match;
        end
    end
end

function name = selectedName(chosen)
    name = "";
    for fieldName = ["displayName", "name", "path"]
        field = char(fieldName);
        if isfield(chosen, field)
            value = string(chosen.(field));
            if isempty(value)
                continue;
            end
            value = value(1);
            if strlength(value) > 0
                name = value;
                return;
            end
        end
    end
end

function refreshFigureTitle(fig, context)
    if ~isprop(fig, 'Name')
        return;
    end
    baseTitle = stripFileContextSuffix(fig.Name);
    if isValidContext(context)
        fig.Name = char(string(baseTitle) + " | " + fileContextSuffix(context));
    else
        fig.Name = baseTitle;
    end
end

function refreshPreviewTitles(ui)
    names = fieldnames(ui.controls);
    for k = 1:numel(names)
        control = ui.controls.(names{k});
        if ~isfield(control, 'kind') || ~strcmp(control.kind, 'previewArea')
            continue;
        end
        axesList = previewAxes(control);
        for n = 1:numel(axesList)
            ax = axesList(n);
            if isgraphics(ax) && isprop(ax, 'Title')
                title(ax, fileContextTitle(ui, ax.Title.String));
            end
        end
    end
end

function axesList = previewAxes(control)
    axesList = gobjects(0);
    if isfield(control, 'axes')
        axesList = control.axes;
    elseif isfield(control, 'primaryAxes')
        axesList = control.primaryAxes;
    end
end

function tf = isValidContext(context)
    tf = isstruct(context) && isfield(context, 'valid') && ...
        isscalar(context.valid) && logical(context.valid);
end

function suffix = fileContextSuffix(context)
    suffix = sprintf('file %d/%d: %s', context.index, ...
        context.count, char(string(context.name)));
end

function titleText = stripFileContextSuffix(titleText)
    titleText = regexprep(char(string(titleText)), ...
        '\s\|\sfile\s+\d+/\d+:\s.*$', '');
end
