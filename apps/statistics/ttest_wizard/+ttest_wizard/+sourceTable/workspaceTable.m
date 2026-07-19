function tableNode = workspaceTable()
%WORKSPACETABLE Build the selectable source-table workspace node.
%
% Expected caller: workbench.buildLayout.

tableNode = labkit.app.layout.dataTable("sourceGrid", ...
    Columns="A", RowNames="1", ...
    OnCellSelectionChanged=@ttest_wizard.sourceTable.selectCells);
end
