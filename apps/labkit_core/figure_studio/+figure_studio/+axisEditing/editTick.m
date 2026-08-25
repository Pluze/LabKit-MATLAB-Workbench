%EDITTICK Apply one per-tick value, label, visibility, level, or style edit.
function state = editTick(state, edit, callbackContext)
arguments
    state (1, 1) struct
    edit (1, 1) labkit.app.event.TableCellEdit
    callbackContext (1, 1) labkit.app.CallbackContext
end
before = state.session.editor.document;
document = before;
[panelIndex, axisName, axisValue] = activeAxis(state.session.editor);
row = edit.RowIndex;
if row > numel(axisValue.ticks)
    return;
end
try
    switch edit.ColumnIndex
        case 1
            axisValue.ticks(row).value = finiteNumber(edit.NewValue, "Tick value");
        case 2
            axisValue.ticks(row).label = string(edit.NewValue);
        case 3
            axisValue.ticks(row).visible = logicalValue(edit.NewValue);
        case 4
            level = lower(string(edit.NewValue));
            if ~any(level == ["major", "minor"])
                error("figure_studio:axisEditing:InvalidTickLevel", ...
                    "Tick level must be major or minor.");
            end
            axisValue.ticks(row).level = level;
        case 5
            axisValue.ticks(row).rotation = finiteNumber( ...
                edit.NewValue, "Tick rotation");
        case 6
            axisValue.ticks(row).fontOverride = optionalFontSize( ...
                axisValue.ticks(row).fontOverride, edit.NewValue);
        case 7
            axisValue.ticks(row).fontOverride = optionalWeight( ...
                axisValue.ticks(row).fontOverride, edit.NewValue);
        case 8
            axisValue.ticks(row).fontOverride = optionalColor( ...
                axisValue.ticks(row).fontOverride, edit.NewValue);
    end
    [~, order] = sort([axisValue.ticks.value]);
    axisValue.ticks = axisValue.ticks(order);
    axisValue = synchronizeExplicit(axisValue);
catch exception
    state.session.workflow.status = string(exception.message);
    callbackContext.log("info", "figure_studio.axisediting.edittick.rejected", ...
        state.session.workflow.status);
    return;
end
document.panels(panelIndex).axes.(axisName) = axisValue;
state = figure_studio.axisEditing.commitDocument( ...
    state, before, document, "Edit tick");
end

function [panelIndex, axisName, axisValue] = activeAxis(editor)
panelIndex = find(string({editor.document.panels.id}) == editor.activePanelId, 1);
if isempty(panelIndex), panelIndex = 1; end
axisName = lower(char(editor.axisTarget));
axisValue = editor.document.panels(panelIndex).axes.(axisName);
end

function axisValue = synchronizeExplicit(axisValue)
axisValue.locator.mode = "explicit";
axisValue.locator.values = [axisValue.ticks.value];
axisValue.formatter.mode = "explicit";
axisValue.formatter.labels = string({axisValue.ticks.label});
end

function value = finiteNumber(value, label)
if ischar(value) || isstring(value), value = str2double(string(value)); end
value = double(value);
if ~isscalar(value) || ~isfinite(value)
    error("figure_studio:axisEditing:InvalidTickValue", ...
        "%s must be a finite scalar.", label);
end
end

function value = logicalValue(value)
if islogical(value) && isscalar(value), return; end
text = lower(strtrim(string(value)));
if any(text == ["true", "on", "yes", "1"]), value = true;
elseif any(text == ["false", "off", "no", "0"]), value = false;
else
    error("figure_studio:axisEditing:InvalidTickVisibility", ...
        "Tick visibility must be true or false.");
end
end

function owner = optionalFontSize(owner, value)
if isempty(value) || strlength(strtrim(string(value))) == 0
    owner = removeField(owner, "FontSize");
    return;
end
value = finiteNumber(value, "Tick font size");
if value <= 0
    error("figure_studio:axisEditing:InvalidTickFontSize", ...
        "Tick font size must be positive.");
end
owner.FontSize = value;
end

function owner = optionalWeight(owner, value)
value = lower(strtrim(string(value)));
if strlength(value) == 0
    owner = removeField(owner, "FontWeight");
elseif any(value == ["normal", "bold"])
    owner.FontWeight = value;
else
    error("figure_studio:axisEditing:InvalidTickWeight", ...
        "Tick weight must be normal, bold, or blank.");
end
end

function owner = optionalColor(owner, value)
value = strtrim(string(value));
if strlength(value) == 0
    owner = removeField(owner, "Color");
    return;
end
parts = str2double(split(replace(value, ",", " ")));
parts = parts(isfinite(parts));
if numel(parts) ~= 3 || any(parts < 0 | parts > 1)
    error("figure_studio:axisEditing:InvalidTickColor", ...
        "Tick color must contain three values from 0 to 1.");
end
owner.Color = reshape(parts, 1, 3);
end

function owner = removeField(owner, name)
if isfield(owner, name), owner = rmfield(owner, name); end
end
