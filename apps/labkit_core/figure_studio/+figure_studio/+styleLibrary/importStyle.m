%IMPORTSTYLE Load and validate a reusable Figure Studio style.
function state = importStyle(state, context)
choice = context.chooseInputFile( ...
    ["*.mat", "Figure Studio style (*.mat)"], pwd);
if choice.Cancelled, return; end
payload = load(string(choice.Value), "style", "schema");
if ~isfield(payload, "schema") || string(payload.schema) ~= ...
        "figure-studio-style" || ~isfield(payload, "style") || ...
        ~isstruct(payload.style) || ~isscalar(payload.style)
    context.alert("The selected file is not a Figure Studio style.", ...
        "Figure Studio");
    return;
end
state.project.parameters.style = validatedStyle(payload.style);
state.project.parameters.preset = "Custom imported";
state.project.parameters.gridChoice = onOff( ...
    state.project.parameters.style.gridVisible);
state.project.parameters.boundaryChoice = onOff( ...
    state.project.parameters.style.boundaryLines);
state.session.cache.viewRevision = state.session.cache.viewRevision + 1;
state.session.workflow.status = "Imported reusable figure style.";
state.project.results.lastExport = [];
state.project.results.lastOutputPath = "";
context.log("info", "figure_studio.style.imported", ...
    state.session.workflow.status);
end

function style = validatedStyle(candidate)
style = figure_studio.styleLibrary.styleForPreset("LabKit figure");
allowed = string(fieldnames(style));
for name = reshape(intersect(string(fieldnames(candidate)), allowed, 'stable'), 1, [])
    style.(char(name)) = candidate.(char(name));
end
numericPositive = ["baseFontSize", "titleFontSize", "labelFontSize", ...
    "tickFontSize", "annotationFontSize", "legendFontSize", ...
    "dataLineWidth", "uncertaintyLineWidth", "boundaryLineWidth", ...
    "referenceLineWidth", "axesLineWidth", "canvasWidth", ...
    "canvasHeight", "exportScale"];
for name = numericPositive
    value = double(style.(char(name)));
    if ~isscalar(value) || ~isfinite(value) || value <= 0
        error("figure_studio:styleLibrary:InvalidStyle", ...
            "Imported style field %s must be a positive finite scalar.", name);
    end
end
if ~isnumeric(style.colorOrder) || size(style.colorOrder, 2) ~= 3 || ...
        any(~isfinite(style.colorOrder), 'all')
    error("figure_studio:styleLibrary:InvalidStyle", ...
        "Imported colorOrder must be a finite N-by-3 numeric array.");
end
style.name = "Custom imported";
end

function value = onOff(tf)
if tf, value = "On"; else, value = "Off"; end
end
