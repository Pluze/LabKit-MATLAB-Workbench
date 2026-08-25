%CHANGE Apply one axis or text edit as an undoable presentation transaction.
function state = change(state, property, value, callbackContext)
if isempty(state.session.editor.document.panels), return; end
before = state.session.editor.document;
document = before;
panelIndex = activePanelIndex(state.session.editor);
axisName = char(figure_studio.axisEditing.axisField( ...
    state.session.editor.axisTarget));
axisValue = document.panels(panelIndex).axes.(axisName);
property = string(property);
try
    switch property
        case {"title", "subtitle", "xLabel", "yLabel", "yRightLabel"}
            document.panels(panelIndex).text.(char(property)) = string(value);
        case "scale"
            value = lower(string(value));
            if value == "log" && axisValue.limits(1) <= 0
                error("figure_studio:axisEditing:InvalidLogLimits", ...
                    "A logarithmic axis requires positive limits.");
            end
            axisValue.scale = value;
            if value == "log" && any(lower(string(axisValue.locator.mode)) == ...
                    ["auto", "nice-count", "source"])
                axisValue.locator.mode = "log";
            elseif value == "linear" && lower(string(axisValue.locator.mode)) == "log"
                axisValue.locator.mode = "auto";
            end
            axisValue.ticks = figure_studio.figureDocument.planTicks(axisValue);
        case "direction"
            axisValue.direction = lower(string(value));
        case {"minimum", "maximum"}
            limit = double(value);
            if ~isscalar(limit) || ~isfinite(limit)
                error("figure_studio:axisEditing:InvalidLimit", ...
                    "Axis limits must be finite scalar values.");
            end
            limits = axisValue.limits;
            if property == "minimum", limits(1) = limit;
            else, limits(2) = limit; end
            if limits(1) >= limits(2) || ...
                    (axisValue.scale == "log" && limits(1) <= 0)
                error("figure_studio:axisEditing:InvalidLimits", ...
                    "Axis minimum must be below maximum and log limits must be positive.");
            end
            axisValue.limits = limits;
            if lower(string(axisValue.locator.mode)) == "source"
                axisValue.locator.mode = "auto";
                axisValue.formatter.mode = "auto";
            end
            axisValue.ticks = figure_studio.figureDocument.planTicks(axisValue);
        case "location"
            location = lower(string(value));
            if location == "auto", location = ""; end
            if axisName == "x" && ~any(location == ["", "bottom", "top", "origin"])
                error("figure_studio:axisEditing:InvalidLocation", ...
                    "X-axis position must be bottom, top, origin, or auto.");
            elseif any(axisName == ["y", "yRight"]) && ...
                    ~any(location == ["", "left", "right", "origin"])
                error("figure_studio:axisEditing:InvalidLocation", ...
                    "Y-axis position must be left, right, origin, or auto.");
            end
            axisValue.location = location;
        case "locator"
            axisValue.locator.mode = locatorMode(value, axisValue.scale);
            axisValue.ticks = figure_studio.figureDocument.planTicks(axisValue);
        case "count"
            axisValue.locator.count = round(double(value));
            if any(lower(string(axisValue.locator.mode)) == ["auto", "nice-count"])
                axisValue.ticks = figure_studio.figureDocument.planTicks(axisValue);
            end
        case "step"
            axisValue.locator.step = double(value);
            if lower(string(axisValue.locator.mode)) == "fixed-step"
                axisValue.ticks = figure_studio.figureDocument.planTicks(axisValue);
            end
        case "formatter"
            axisValue.formatter.mode = lower(string(value));
            if axisValue.formatter.mode == "auto"
                axisValue.formatter.mode = "auto";
            end
            axisValue.ticks = figure_studio.figureDocument.planTicks(axisValue);
        case "precision"
            axisValue.formatter.precision = round(double(value));
            axisValue.ticks = figure_studio.figureDocument.planTicks(axisValue);
        case {"prefix", "suffix"}
            axisValue.formatter.(char(property)) = string(value);
            axisValue.ticks = figure_studio.figureDocument.planTicks(axisValue);
        otherwise
            error("figure_studio:axisEditing:UnknownEdit", ...
                "Unknown axis edit: %s", property);
    end
    if ~any(property == ["title", "subtitle", "xLabel", "yLabel", ...
            "yRightLabel"])
        document.panels(panelIndex).axes.(axisName) = axisValue;
    end
catch exception
    state.session.workflow.status = string(exception.message);
    callbackContext.log("info", "figure_studio.axisediting.change.rejected", ...
        state.session.workflow.status);
    return;
end
state = figure_studio.axisEditing.commitDocument( ...
    state, before, document, "Edit " + property);
callbackContext.log("info", "figure_studio.axisediting.change.status", ...
    state.session.workflow.status);
end

function mode = locatorMode(value, scale)
value = lower(string(value));
if value == "auto" && lower(string(scale)) == "log"
    mode = "log";
elseif value == "auto"
    mode = "auto";
elseif value == "nice count"
    mode = "nice-count";
elseif value == "fixed step"
    mode = "fixed-step";
else
    mode = "explicit";
end
end

function index = activePanelIndex(editor)
index = find(string({editor.document.panels.id}) == editor.activePanelId, 1);
if isempty(index), index = 1; end
end
