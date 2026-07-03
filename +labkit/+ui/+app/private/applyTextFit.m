% Private UI app helper. Expected caller: UI 4.0 control builders. Inputs are
% a MATLAB UI text-bearing handle and optional fitting limits. Output is none.
% Side effects: enables wrapping when supported, reduces font size for long
% text, and installs a tooltip with the full text when supported.
function applyTextFit(handle, varargin)
    opts = parseOptions(varargin{:});
    text = controlText(handle);
    if strlength(text) == 0
        return;
    end

    enableWrap(handle);
    applyShrink(handle, text, opts);
    applyTooltip(handle, text);
end

function opts = parseOptions(varargin)
    opts = struct( ...
        'baseFontSize', NaN, ...
        'minFontSize', 10, ...
        'charsPerStep', 28, ...
        'maxShrinkSteps', 3);
    for k = 1:2:numel(varargin)
        name = char(string(varargin{k}));
        if k + 1 <= numel(varargin) && isfield(opts, name)
            opts.(name) = varargin{k + 1};
        end
    end
end

function enableWrap(handle)
    if ~isprop(handle, 'WordWrap')
        return;
    end
    try
        if ~strcmp(handle.WordWrap, 'on')
            handle.WordWrap = 'on';
        end
    catch
    end
end

function applyShrink(handle, text, opts)
    if ~isprop(handle, 'FontSize')
        return;
    end
    try
        baseSize = double(handle.FontSize);
        if isfinite(opts.baseFontSize)
            baseSize = double(opts.baseFontSize);
        end
        longestLine = max(strlength(splitlines(text)));
        shrinkSteps = max(0, ceil(double(longestLine) ./ opts.charsPerStep) - 1);
        shrinkSteps = min(double(opts.maxShrinkSteps), shrinkSteps);
        targetSize = max(double(opts.minFontSize), baseSize - shrinkSteps);
        if handle.FontSize ~= targetSize
            handle.FontSize = targetSize;
        end
    catch
    end
end

function applyTooltip(handle, text)
    tooltip = char(text);
    if isprop(handle, 'Tooltip')
        try
            if ~strcmp(handle.Tooltip, tooltip)
                handle.Tooltip = tooltip;
            end
            return;
        catch
        end
    end
    if isprop(handle, 'TooltipString')
        try
            if ~strcmp(handle.TooltipString, tooltip)
                handle.TooltipString = tooltip;
            end
        catch
        end
    end
end

function text = controlText(handle)
    text = "";
    if isprop(handle, 'Text')
        try
            text = string(handle.Text);
            text = join(text(:), newline);
            return;
        catch
        end
    end
    if isprop(handle, 'Value')
        try
            value = handle.Value;
            if iscell(value)
                text = join(string(value(:)), newline);
            else
                text = string(value);
                text = join(text(:), newline);
            end
        catch
            text = "";
        end
    end
end
