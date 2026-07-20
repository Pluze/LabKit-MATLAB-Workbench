% Private App SDK native-adapter implementation for applyTextFit; called only by the internal runtime.
function applyTextFit(handle, varargin)
% Private native adapter helper. Keeps complete reader-facing text available
% when a component is narrower than its preferred size.
options = struct( ...
    "CharsPerStep", 28, "MaxShrinkSteps", 3, "MinFontSize", 10);
for k = 1:2:numel(varargin)
    name = string(varargin{k});
    if k + 1 <= numel(varargin) && isfield(options, name)
        options.(name) = varargin{k + 1};
    end
end
text = componentText(handle);
if strlength(text) == 0
    return
end
if isprop(handle, "WordWrap")
    handle.WordWrap = "on";
end
if isprop(handle, "Tooltip") && strlength(string(handle.Tooltip)) == 0
    handle.Tooltip = char(text);
end
if ~isprop(handle, "FontSize")
    return
end
key = "labkitAppTextFitBaseFontSize";
if isappdata(handle, key)
    baseFontSize = getappdata(handle, key);
else
    baseFontSize = handle.FontSize;
    setappdata(handle, key, baseFontSize);
end
longest = max(strlength(splitlines(text)));
steps = max(0, ceil(double(longest) / options.CharsPerStep) - 1);
steps = min(options.MaxShrinkSteps, steps);
handle.FontSize = max(options.MinFontSize, baseFontSize - steps);
end

function text = componentText(handle)
text = "";
if isprop(handle, "Text")
    text = normalizedComponentText(handle.Text);
elseif isprop(handle, "Value")
    text = normalizedComponentText(handle.Value);
end
end

function text = normalizedComponentText(value)
if ischar(value)
    if isrow(value) || isempty(value)
        text = string(value);
    else
        text = join(string(value), newline);
    end
else
    text = join(string(value(:)), newline);
end
end
