function tableNode = workspaceTable()
%WORKSPACETABLE Build the editable analysis-data workspace node.
%
% Expected caller: workbench.buildLayout.

tableNode = labkit.app.layout.dataTable("dataTable", ...
    Columns=["Group", "Value"], ColumnEditable=[true true], ...
    OnCellEdited=@ttest_wizard.groupData.replaceFromTableEdit, ...
    OnCellSelectionChanged=@ttest_wizard.groupData.selectRows);
end
