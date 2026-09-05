function view = present(editor)
%PRESENT Display live legend labels, row order, and inclusion controls.
rows = figure_studio.legendEditing.rows(editor.document, editor.activePanelId);
data = cell(numel(rows), 4);
for k = 1:numel(rows)
    data(k, :) = {char(rows(k).sourceLabel), char(rows(k).label), k, rows(k).enabled};
end
view = labkit.app.view.Snapshot().tableData("legendTable", data, ...
    Columns=["Original name", "Legend name", "Position", "Show"], ...
    ColumnEditable=[false true true true]);
end
