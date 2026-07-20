function state = refreshStyle(state, changedId)
%REFRESHSTYLE Reconcile one bound style edit with linked Figure Studio state.
arguments
    state (1, 1) struct
    changedId (1, 1) string
end
p = state.project.parameters;
p.style = sanitizeStyle(p.style);
if changedId == "baseFontSize"
    p.style.titleFontSize = p.style.baseFontSize;
    p.style.labelFontSize = p.style.baseFontSize;
    p.style.tickFontSize = p.style.baseFontSize;
    p.style = clearFontOverrides(p.style);
elseif any(changedId == ...
        ["titleFontSize", "labelFontSize", "tickFontSize"])
    p.style = markFontOverride(p.style, changedId);
elseif changedId == "gridVisible"
    p.style.gridVisible = p.gridChoice == "On";
elseif changedId == "boundaryLines"
    p.style.boundaryLines = p.boundaryChoice == "On";
end
p.style = applyAspectPreset(p.style, p.aspectPreset, changedId);
state.project.parameters = p;
state.session.workflow.status = "Styled with " + p.preset + ".";
state.project.results.lastExport = [];
state.project.results.resultManifestPath = "";
end

function style = sanitizeStyle(style)
defaults = figure_studio.styleLibrary.styleForPreset("LabKit figure");
names = ["baseFontSize", "titleFontSize", "labelFontSize", ...
    "tickFontSize", "dataLineWidth", "axesLineWidth", ...
    "gridAlpha", "canvasWidth", "canvasHeight", "exportScale"];
for name = names
    field = char(name);
    style.(field) = finiteValue(style.(field), defaults.(field));
end
style.gridAlpha = min(max(style.gridAlpha, 0), 1);
style.canvasWidth = min(max(style.canvasWidth, 400), 8000);
style.canvasHeight = min(max(style.canvasHeight, 300), 8000);
style.exportScale = min(max(style.exportScale, 1), 8);
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

function style = applyAspectPreset(style, preset, changedId)
ratio = aspectRatio(preset);
if ~isfinite(ratio)
    return
end
if changedId == "aspectPreset" || changedId == "canvasWidth"
    style.canvasHeight = max(1, round(style.canvasWidth / ratio));
elseif changedId == "canvasHeight"
    style.canvasWidth = max(1, round(style.canvasHeight * ratio));
end
end

function ratio = aspectRatio(preset)
switch string(preset)
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

function value = finiteValue(value, fallback)
value = double(value);
if isempty(value) || ~isscalar(value) || ~isfinite(value)
    value = fallback;
end
end
