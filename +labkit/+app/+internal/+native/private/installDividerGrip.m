function installDividerGrip(target, orientation, beginDrag)
% Every part of the 24-pixel strip starts the same drag. Only its edge is inked.
style = labkit.app.internal.native.lightAppearance();
if orientation == "column"
    rows = {'1x',28,'1x'};
    columns = {'1x',1,1};
else
    rows = {'1x',1,1,'1x'};
    columns = {'1x',28,'1x'};
end
grid = uigridlayout(target, [numel(rows) numel(columns)], ...
    Padding=[0 0 0 0], RowSpacing=0, ColumnSpacing=0, ...
    RowHeight=rows, ColumnWidth=columns);
surface = uipanel(grid, BorderType="none", BackgroundColor=style.Background, ...
    ButtonDownFcn=beginDrag);
surface.Layout.Row = [1 numel(rows)];
surface.Layout.Column = [1 numel(columns)];
target.UserData = surface;
rule = uipanel(grid, BorderType="none", BackgroundColor=style.Line, ...
    Tag="labkitDividerRule", ButtonDownFcn=beginDrag);
grip = uipanel(grid, BorderType="none", BackgroundColor=style.Muted, ...
    Tag="labkitDividerGrip", ButtonDownFcn=beginDrag);
if orientation == "column"
    rule.Layout.Row = [1 3];
    rule.Layout.Column = 3;
    grip.Layout.Row = 2;
    grip.Layout.Column = [2 3];
else
    rule.Layout.Row = 2;
    rule.Layout.Column = [1 3];
    grip.Layout.Row = [2 3];
    grip.Layout.Column = 2;
end
end
