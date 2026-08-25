%LAYOUTSECTION Declare canvas, panel geometry, sharing, and alignment controls.
function section = layoutSection()
section = labkit.app.layout.section("documentGeometry", "Canvas + Panels", { ...
    labkit.app.layout.group("canvasDimensions", { ...
        numeric("documentWidth", "Width (px)", [100 10000], @changeWidth), ...
        numeric("documentHeight", "Height (px)", [100 10000], @changeHeight)}), ...
    labkit.app.layout.group("canvasPadding", { ...
        numeric("paddingLeft", "Left", [0 2000], @changeLeft), ...
        numeric("paddingRight", "Right", [0 2000], @changeRight), ...
        numeric("paddingTop", "Top", [0 2000], @changeTop), ...
        numeric("paddingBottom", "Bottom", [0 2000], @changeBottom)}), ...
    labkit.app.layout.dataTable("panelTable", Title="Panel geometry (normalized)", ...
        Columns=["Name", "X", "Y", "Width", "Height", "Shared X", ...
            "Shared Y", "Lock"], ...
        ColumnEditable=true(1, 8), OnCellEdited=@editPanel, ...
        OnCellSelectionChanged=@selectPanels), ...
    labkit.app.layout.group("panelLifecycle", { ...
        labkit.app.layout.button("duplicatePanels", "Duplicate", @duplicate), ...
        labkit.app.layout.button("deletePanels", "Delete", @deleteSelected), ...
        labkit.app.layout.button("autoGridPanels", "Auto grid", @autoGrid)}), ...
    labkit.app.layout.group("panelAlignment", { ...
        operationButton("alignPanelsLeft", "Align left", @alignLeft), ...
        operationButton("alignPanelsRight", "Align right", @alignRight), ...
        operationButton("alignPanelsTop", "Align top", @alignTop), ...
        operationButton("alignPanelsBottom", "Align bottom", @alignBottom), ...
        operationButton("equalPanelWidth", "Equal width", @equalWidth), ...
        operationButton("equalPanelHeight", "Equal height", @equalHeight), ...
        operationButton("distributePanelsH", "Distribute H", @distributeH), ...
        operationButton("distributePanelsV", "Distribute V", @distributeV)})});
end

function node = numeric(id, label, limits, callback)
node = labkit.app.layout.field(id, Label=label, Kind="numeric", ...
    Limits=limits, OnValueChanged=callback);
end

function node = operationButton(id, label, callback)
node = labkit.app.layout.button(id, label, callback);
end

function state = changeWidth(state, value, context), state = canvas(state, 1, value, context); end
function state = changeHeight(state, value, context), state = canvas(state, 2, value, context); end
function state = changeLeft(state, value, context), state = padding(state, 1, value, context); end
function state = changeRight(state, value, context), state = padding(state, 2, value, context); end
function state = changeTop(state, value, context), state = padding(state, 3, value, context); end
function state = changeBottom(state, value, context), state = padding(state, 4, value, context); end

function state = canvas(state, dimension, value, ~)
before = state.session.editor.document;
document = before;
if dimension == 1
    document.canvas.width = double(value);
else
    document.canvas.height = double(value);
end
state.session.editor.nativePassThrough = false;
state = figure_studio.axisEditing.commitDocument(state, before, document, ...
    "Resize canvas");
end

function state = padding(state, index, value, ~)
before = state.session.editor.document;
document = before;
document.canvas.padding(index) = double(value);
state.session.editor.nativePassThrough = false;
state = figure_studio.axisEditing.commitDocument(state, before, document, ...
    "Edit canvas padding");
end

function state = selectPanels(state, selection, ~)
rows = unique(selection.CellIndices(:, 1));
rows = rows(rows <= numel(state.session.editor.document.panels));
ids = string({state.session.editor.document.panels(rows).id}).';
state.session.editor.selectedPanelIds = ids;
if ~isempty(ids)
    state.session.editor.activePanelId = ids(1);
    state.session.cache.plotData = figure_studio.figureDocument.toPlotData( ...
        state.session.editor.document, ids(1));
    state.session.cache.viewRevision = state.session.cache.viewRevision + 1;
end
end

function state = editPanel(state, edit, context)
if edit.RowIndex > numel(state.session.editor.document.panels), return; end
before = state.session.editor.document;
document = before;
panel = document.panels(edit.RowIndex);
try
    switch edit.ColumnIndex
        case 1, panel.name = requiredText(edit.NewValue);
        case {2, 3, 4, 5}
            geometryIndex = edit.ColumnIndex - 1;
            panel.geometry(geometryIndex) = double(edit.NewValue);
            panel.geometry = validGeometry(panel.geometry);
        case 6, panel.sharedXGroup = string(edit.NewValue);
        case 7, panel.sharedYGroup = string(edit.NewValue);
        case 8, panel.locked = logicalValue(edit.NewValue);
    end
catch exception
    state.session.workflow.status = string(exception.message);
    context.log("info", "figure_studio.layout.panel.rejected", ...
        state.session.workflow.status);
    return;
end
document.panels(edit.RowIndex) = panel;
state.session.editor.nativePassThrough = false;
state = figure_studio.axisEditing.commitDocument(state, before, document, ...
    "Edit panel");
end

function state = duplicate(state, ~)
before = state.session.editor.document;
[document, ids] = figure_studio.figureDocument.duplicatePanels( ...
    before, selectedIds(state));
state.session.editor.selectedPanelIds = ids;
if ~isempty(ids), state.session.editor.activePanelId = ids(1); end
state.session.editor.nativePassThrough = false;
state = figure_studio.axisEditing.commitDocument(state, before, document, ...
    "Duplicate panel");
end

function state = deleteSelected(state, context)
before = state.session.editor.document;
try
    document = figure_studio.figureDocument.deletePanels( ...
        before, selectedIds(state));
catch exception
    state.session.workflow.status = string(exception.message);
    context.log("info", "figure_studio.layout.panel.rejected", ...
        state.session.workflow.status);
    return;
end
state.session.editor.activePanelId = document.panels(1).id;
state.session.editor.selectedPanelIds = document.panels(1).id;
state.session.editor.nativePassThrough = false;
state = figure_studio.axisEditing.commitDocument(state, before, document, ...
    "Delete panel");
end

function state = autoGrid(state, context)
state = operate(state, "Auto grid", context);
end

function state = alignLeft(state, context), state = operate(state, "Align left", context); end
function state = alignRight(state, context), state = operate(state, "Align right", context); end
function state = alignTop(state, context), state = operate(state, "Align top", context); end
function state = alignBottom(state, context), state = operate(state, "Align bottom", context); end
function state = equalWidth(state, context), state = operate(state, "Equal width", context); end
function state = equalHeight(state, context), state = operate(state, "Equal height", context); end
function state = distributeH(state, context), state = operate(state, "Distribute horizontally", context); end
function state = distributeV(state, context), state = operate(state, "Distribute vertically", context); end

function state = operate(state, operation, ~)
before = state.session.editor.document;
document = figure_studio.figureDocument.panelOperation( ...
    before, selectedIds(state), operation);
state.session.editor.nativePassThrough = false;
state = figure_studio.axisEditing.commitDocument(state, before, document, ...
    operation + " panels");
end

function ids = selectedIds(state)
ids = state.session.editor.selectedPanelIds;
if isempty(ids), ids = state.session.editor.activePanelId; end
end

function value = requiredText(value)
value = strtrim(string(value));
if strlength(value) == 0, error("Panel name cannot be empty."); end
end

function value = logicalValue(value)
if islogical(value), return; end
value = any(lower(string(value)) == ["true", "on", "yes", "1"]);
end

function geometry = validGeometry(geometry)
geometry = double(reshape(geometry, 1, 4));
if any(~isfinite(geometry)) || any(geometry(3:4) <= 0) || ...
        any(geometry(1:2) < 0) || any(geometry(1:2) + geometry(3:4) > 1)
    error("figure_studio:layoutEditing:InvalidGeometry", ...
        "Panel X, Y, width, and height must fit inside normalized 0–1 bounds.");
end
end
