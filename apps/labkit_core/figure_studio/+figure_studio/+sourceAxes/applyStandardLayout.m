% Expected callers: Figure Studio axes handoff and source-selection actions.
% Inputs are the active editable style and optional portable plot data. Output
% retains the active semantic style while restoring
% the calibrated reference frame and adapting long categorical labels without
% changing the measured panel proportions.
function [style, aspectPreset, canvasSize] = applyStandardLayout(style, plotData)
%APPLYSTANDARDLAYOUT Restore the calibrated Studio layout for an import.
arguments
    style (1, 1) struct
    plotData = []
end

reference = figure_studio.styleLibrary.goldStandard();
aspectPreset = "Reference";
canvasSize = string(reference.canvasWidth) + " px";
style.canvasWidth = reference.canvasWidth;
style.canvasHeight = reference.canvasHeight;
style.referenceCanvasWidth = reference.canvasWidth;
style.referenceCanvasHeight = reference.canvasHeight;
if shouldWrapCategoryLabels(plotData, style)
    style.xTickLabelAngle = "Horizontal";
    style.wrapXTickLabels = true;
else
    style.xTickLabelAngle = "Horizontal";
    style.wrapXTickLabels = false;
end
end

function tf = shouldWrapCategoryLabels(plotData, style)
tf = false;
if ~isstruct(plotData) || ~isscalar(plotData) || ...
        ~isfield(plotData, "axes") || ~isstruct(plotData.axes) || ...
        ~isfield(plotData.axes, "xTickLabel")
    return;
end
labels = strip(string(plotData.axes.xTickLabel));
labels = labels(:);
labels(labels == "") = [];
if isempty(labels) || all(isfinite(str2double(labels)))
    return;
end
fontSize = finitePositiveField(style, "tickFontSize");
canvasWidth = finitePositiveField(style, "canvasWidth");
if ~isfinite(fontSize) || ~isfinite(canvasWidth)
    return;
end
% Use the documented upper calibration density (96 PPI) and a conservative
% sans-serif average glyph width. Wrapping changes label layout while leaving
% the calibrated plot frame, typography, and stroke ratios untouched.
pixelsPerPoint = 96 / 72;
averageGlyphEm = 0.62;
widestLabel = pixelsPerPoint * fontSize * averageGlyphEm * ...
    max(strlength(labels));
categorySlot = canvasWidth / numel(labels);
tf = widestLabel > 0.9 * categorySlot;
end

function value = finitePositiveField(owner, name)
value = NaN;
field = char(name);
if ~isfield(owner, field)
    return;
end
candidate = double(owner.(field));
if isscalar(candidate) && isfinite(candidate) && candidate > 0
    value = candidate;
end
end
