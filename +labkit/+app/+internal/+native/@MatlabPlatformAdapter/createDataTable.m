function table = createDataTable(obj, node, parent)
% Class-folder implementation of MatlabPlatformAdapter.createDataTable.
    config = node.Configuration;
    title = config.Title;
    owner = obj.owningNode(node.Id);
    if strlength(title) == 0 && ~isempty(owner) && ...
            owner.Kind == "section" && ...
            isfield(owner.Configuration, "Title")
        title = owner.Configuration.Title;
    end
    panel = uipanel(parent, Title=char(title));
    grid = uigridlayout(panel, [1 1], Padding=[8 8 8 8]);
    table = uitable(grid, ...
        ColumnName=cellstr(config.Columns), ...
        RowName=cellstr(config.RowNames), ...
        ColumnEditable=config.ColumnEditable);
    table.UserData = struct("LayoutContainer", panel);
    panel.Tag = char(node.Id + ".panel");
end
