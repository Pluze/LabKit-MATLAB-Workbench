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
if isprop(handle, "Tooltip")
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
    text = join(string(handle.Text(:)), newline);
elseif isprop(handle, "Value")
    text = join(string(handle.Value(:)), newline);
end
end
