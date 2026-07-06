% Private UI plot helper. Expected caller: preview title helpers.
% Inputs are a UI registry and a base title. Output is the base title with
% the current filePanel selection suffix appended when one exists.
function titleText = fileContextTitle(ui, titleText)
    titleText = stripFileContextSuffix(char(string(titleText)));
    context = currentFileContext(ui);
    if ~isValidContext(context)
        return;
    end

    suffix = fileContextSuffix(context);
    if strlength(string(titleText)) == 0
        titleText = char(suffix);
    else
        titleText = char(string(titleText) + " | " + suffix);
    end
end

function context = currentFileContext(ui)
    context = struct('valid', false);
    if ~(isstruct(ui) && isfield(ui, 'figure'))
        return;
    end
    fig = ui.figure;
    if isempty(fig) || ~isvalid(fig) || ~isappdata(fig, 'labkitSelectedFileContext')
        return;
    end
    value = getappdata(fig, 'labkitSelectedFileContext');
    if isstruct(value) && isscalar(value)
        context = value;
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
