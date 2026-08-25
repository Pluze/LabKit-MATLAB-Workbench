%CHANGE Apply one axis or text edit as an undoable presentation transaction.
function state = change(state, property, value, callbackContext)
if isempty(state.session.editor.document.panels), return; end
before = state.session.editor.document;
document = before;
panelIndex = activePanelIndex(state.session.editor);
axisName = lower(char(state.session.editor.axisTarget));
axisValue = document.panels(panelIndex).axes.(axisName);
property = string(property);
try
    switch property
        case {"title", "subtitle", "xLabel", "yLabel"}
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
    if ~any(property == ["title", "subtitle", "xLabel", "yLabel"])
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
