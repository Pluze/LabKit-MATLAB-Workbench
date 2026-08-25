%LAYOUTSECTION Declare color scale and per-tick colorbar editing.
function section = layoutSection()
section = labkit.app.layout.section("colorEditor", "Color Scale", { ...
    labkit.app.layout.field("colorbarVisible", Label="Colorbar", Kind="choice", ...
        Choices=["Off", "On"], OnValueChanged=@changeVisible), ...
    labkit.app.layout.field("colorbarLabel", Label="Label", Kind="text", ...
        OnValueChanged=@changeLabel), ...
    labkit.app.layout.field("colorbarLocation", Label="Location", Kind="choice", ...
        Choices=["eastoutside", "westoutside", "northoutside", ...
            "southoutside", "east", "west", "north", "south"], ...
        OnValueChanged=@changeLocation), ...
    labkit.app.layout.group("colorLimits", { ...
        numeric("colorMin", "Minimum", @changeMinimum), ...
        numeric("colorMax", "Maximum", @changeMaximum)}), ...
    labkit.app.layout.field("colorbarTicks", Label="Tick values", Kind="text", ...
        OnValueChanged=@changeTicks), ...
    labkit.app.layout.field("colorbarTickLabels", Label="Tick labels", Kind="text", ...
        OnValueChanged=@changeTickLabels), ...
    labkit.app.layout.field("colormapName", Label="Colormap", Kind="choice", ...
        Choices=["Source", "parula", "turbo", "gray", "hot", "cool"], ...
        OnValueChanged=@changeColormap)});
end

function node = numeric(id, label, callback)
node = labkit.app.layout.field(id, Label=label, Kind="numeric", ...
    Limits=[-1e100 1e100], OnValueChanged=callback);
end

function state = changeVisible(state, value, context), state = change(state, "enabled", string(value)=="On", context); end
function state = changeLabel(state, value, context), state = change(state, "label", string(value), context); end
function state = changeLocation(state, value, context), state = change(state, "location", string(value), context); end
function state = changeMinimum(state, value, context), state = change(state, "minimum", double(value), context); end
function state = changeMaximum(state, value, context), state = change(state, "maximum", double(value), context); end
function state = changeTicks(state, value, context), state = change(state, "ticks", numericList(value), context); end
function state = changeTickLabels(state, value, context), state = change(state, "tickLabels", split(string(value), "|"), context); end
function state = changeColormap(state, value, context), state = change(state, "colormap", string(value), context); end

function state = change(state, property, value, context)
before = state.session.editor.document;
document = before;
panelIndex = find(string({document.panels.id}) == ...
    state.session.editor.activePanelId, 1);
bar = document.panels(panelIndex).color.bar;
try
    switch property
        case "minimum"
            limits = bar.limits;
            limits(1) = value;
            bar.limits = validateLimits(limits);
            document.panels(panelIndex).color.limits = bar.limits;
        case "maximum"
            limits = bar.limits;
            limits(2) = value;
            bar.limits = validateLimits(limits);
            document.panels(panelIndex).color.limits = bar.limits;
        case "ticks"
            if any(value < bar.limits(1) | value > bar.limits(2))
                error("figure_studio:colorEditing:TicksOutsideLimits", ...
                    "Colorbar ticks must lie inside its limits.");
            end
            bar.ticks = value;
        case "tickLabels"
            if ~isempty(bar.ticks) && numel(value) ~= numel(bar.ticks)
                error("figure_studio:colorEditing:LabelCount", ...
                    "Colorbar labels must match the number of tick values.");
            end
            bar.tickLabels = value;
        case "colormap"
            if value ~= "Source"
                document.panels(panelIndex).color.colormap = map(value);
            end
        otherwise
            bar.(char(property)) = value;
    end
catch exception
    state.session.workflow.status = string(exception.message);
    context.log("info", "figure_studio.color.edit.rejected", ...
        state.session.workflow.status);
    return;
end
document.panels(panelIndex).color.bar = bar;
state.session.editor.nativePassThrough = false;
state = figure_studio.axisEditing.commitDocument(state, before, document, ...
    "Edit color scale");
end

function values = numericList(value)
tokens = split(replace(string(value), ",", " "));
tokens(tokens == "") = [];
values = str2double(tokens).';
if any(~isfinite(values))
    error("figure_studio:colorEditing:InvalidTicks", ...
        "Colorbar tick values must be finite numbers.");
end
end

function limits = validateLimits(limits)
if numel(limits) ~= 2 || any(~isfinite(limits)) || limits(1) >= limits(2)
    error("figure_studio:colorEditing:InvalidLimits", ...
        "Color limits must be finite and increasing.");
end
end

function values = map(name)
switch name
    case "parula", values = parula(256);
    case "turbo", values = turbo(256);
    case "gray", values = gray(256);
    case "hot", values = hot(256);
    case "cool", values = cool(256);
    otherwise
        error("figure_studio:colorEditing:UnknownColormap", ...
            "Unknown colormap: %s", name);
end
end
