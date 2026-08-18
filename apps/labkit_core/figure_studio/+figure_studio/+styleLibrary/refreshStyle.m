% App-owned implementation for figure_studio.styleLibrary.refreshStyle within the figure_studio product workflow.
function state = refreshStyle(state, changedId)
%REFRESHSTYLE Reconcile one bound style edit with linked Figure Studio state.
arguments
    state (1, 1) struct
    changedId (1, 1) string
end
p = state.project.parameters;
p.style = sanitizeStyle(p.style);
p.canvasSize = normalizeCanvasSize(p.canvasSize);
if changedId == "baseFontSize"
    p.style.titleFontSize = p.style.baseFontSize;
    p.style.labelFontSize = p.style.baseFontSize;
    p.style.tickFontSize = p.style.baseFontSize;
    p.style.annotationFontSize = p.style.baseFontSize;
    p.style.legendFontSize = p.style.baseFontSize;
    p.style = clearFontOverrides(p.style);
elseif any(changedId == ...
        ["titleFontSize", "labelFontSize", "tickFontSize"])
    p.style = markFontOverride(p.style, changedId);
elseif changedId == "gridVisible"
    p.style.gridVisible = p.gridChoice == "On";
elseif changedId == "boundaryLines"
    p.style.boundaryLines = p.boundaryChoice == "On";
elseif changedId == "xTickLabelAngle"
    p.style.wrapXTickLabels = false;
end
p.style = applyAspectPreset( ...
    p.style, p.aspectPreset, p.canvasSize, changedId, ...
    state.session.cache.sourceDefaultStyle);
state.project.parameters = p;
state.session.workflow.status = "Styled with " + p.preset + ".";
state.project.results.lastExport = [];
state.project.results.resultManifestPath = "";
end

function style = sanitizeStyle(style)
defaults = figure_studio.styleLibrary.styleForPreset("LabKit figure");
names = ["baseFontSize", "titleFontSize", "labelFontSize", ...
    "tickFontSize", "annotationFontSize", "dataLineWidth", ...
    "uncertaintyLineWidth", "boundaryLineWidth", ...
    "referenceLineWidth", "axesLineWidth", ...
    "gridAlpha", "canvasWidth", "canvasHeight", "exportScale", ...
    "referenceCanvasWidth", "referenceCanvasHeight", ...
    "legendFontSize", "legendNumColumns"];
for name = names
    field = char(name);
    style.(field) = finiteValue(style.(field), defaults.(field));
end
style.gridAlpha = min(max(style.gridAlpha, 0), 1);
style.canvasWidth = min(max(style.canvasWidth, 320), 8000);
style.canvasHeight = min(max(style.canvasHeight, 240), 8000);
style.referenceCanvasWidth = min(max( ...
    style.referenceCanvasWidth, 1), 8000);
style.referenceCanvasHeight = min(max( ...
    style.referenceCanvasHeight, 1), 8000);
style.exportScale = min(max(style.exportScale, 1), 8);
style.legendFontSize = min(max(style.legendFontSize, 4), 96);
style.legendNumColumns = round(min(max(style.legendNumColumns, 0), 12));
end

function style = clearFontOverrides(style)
style = ensureFontOverrides(style);
style.fontOverrides.title = false;
style.fontOverrides.label = false;
style.fontOverrides.tick = false;
end

function style = markFontOverride(style, id)
style = ensureFontOverrides(style);
names = struct("titleFontSize", "title", ...
    "labelFontSize", "label", "tickFontSize", "tick");
style.fontOverrides.(names.(char(id))) = true;
end

function style = ensureFontOverrides(style)
if ~isfield(style, "fontOverrides") || ~isstruct(style.fontOverrides)
    style.fontOverrides = struct( ...
        "title", false, "label", false, "tick", false);
end
end

function style = applyAspectPreset(style, preset, canvasSize, changedId, sourceStyle)
ratio = aspectRatio(preset);
if changedId == "canvasSize"
    style.canvasWidth = figure_studio.styleLibrary.canvasWidthForSize( ...
        string(canvasSize), style.canvasWidth);
    if string(canvasSize) == "Source size" && isstruct(sourceStyle) && ...
            isfield(sourceStyle, "canvasWidth") && ...
            isfinite(sourceStyle.canvasWidth)
        style.canvasWidth = sourceStyle.canvasWidth;
    end
end
if string(preset) == "Source" && isstruct(sourceStyle) && ...
        isfield(sourceStyle, "canvasWidth") && ...
        isfield(sourceStyle, "canvasHeight") && ...
        isfinite(sourceStyle.canvasWidth) && isfinite(sourceStyle.canvasHeight) && ...
        sourceStyle.canvasHeight > 0
    ratio = sourceStyle.canvasWidth / sourceStyle.canvasHeight;
end
if ~isfinite(ratio)
    return
end
if changedId == "aspectPreset" || changedId == "canvasSize"
    style.canvasHeight = max(1, round(style.canvasWidth / ratio));
end
end

function ratio = aspectRatio(preset)
switch string(preset)
    case "Reference"
        reference = figure_studio.styleLibrary.goldStandard();
        ratio = reference.canvasWidth / reference.canvasHeight;
    case "6:5"
        ratio = 6 / 5;
    case "4:3"
        ratio = 4 / 3;
    case "16:9"
        ratio = 16 / 9;
    case "1:1"
        ratio = 1;
    case "3:2"
        ratio = 3 / 2;
    otherwise
        ratio = NaN;
end
end

function choice = normalizeCanvasSize(choice)
[choices, ~] = figure_studio.styleLibrary.canvasSizeOptions();
choice = string(choice);
if ~isscalar(choice) || ~any(choices == choice)
    choice = "900 px";
end
end

function value = finiteValue(value, fallback)
value = double(value);
if isempty(value) || ~isscalar(value) || ~isfinite(value)
    value = fallback;
end
end
