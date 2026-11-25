function frame = installPageNavigation(obj, node, parent, pages)
% A page strip and a single shared canvas for titled workspaces.
style = obj.Appearance;
sidebar = node.Kind == "workbench";
if ~sidebar
    pages = obj.nodes(node.PageIds);
end
ids = string({pages.Id});
active = ids(1);
if ~sidebar && node.InitialPage ~= ""
    active = node.InitialPage;
end
frame = uigridlayout(parent,[1 1],Padding=[0 0 0 0],BackgroundColor=style.Surface);
if sidebar
    columns = min(2,numel(ids));
    rows = ceil(numel(ids)/columns);
    parent.RowHeight = {32*rows+4*(rows-1),'1x'};
    bar = uigridlayout(parent,[rows columns],RowHeight=repmat({32},1,rows), ...
        Padding=[0 0 0 0],ColumnSpacing=4,RowSpacing=4,BackgroundColor=parent.BackgroundColor);
    bar.Layout.Row = 1;
    frame.Layout.Row = 2;
    frame.BackgroundColor = parent.BackgroundColor;
else
    columns = numel(ids);
    bar = uigridlayout(obj.Header,[2 columns+1],RowHeight={'1x',2}, ...
        ColumnWidth=[repmat({'fit'},1,columns),{'1x'}],Padding=[8 0 0 0], ...
        RowSpacing=0,ColumnSpacing=6,Scrollable="on",BackgroundColor=style.Surface);
    bar.Layout.Row = 1;
    bar.Layout.Column = numel(obj.Header.ColumnWidth) - double(isnumeric(obj.Header.ColumnWidth{end}));
    obj.Layouts(char(node.Id)) = frame;
end
canvas = frame;
canvas.UserData = active;
buttons = gobjects(size(ids));
lines = gobjects(size(ids));
for i = 1:numel(ids)
    buttons(i) = uibutton(bar,Text=pages(i).Configuration.Title,Tag=ids(i)+".navigate", ...
        FontWeight="bold",BackgroundColor=style.Surface,Interruptible="off",BusyAction="cancel", ...
        ButtonPushedFcn=@(~,~) ...
        obj.runUserInput(@() selectPage(ids(i))));
    buttons(i).Layout.Row = ceil(i/columns);
    buttons(i).Layout.Column = mod(i-1,columns)+1;
    if ~sidebar
        lines(i) = uilabel(bar,Text="");
        lines(i).Layout.Row = 2;
        lines(i).Layout.Column = i;
    end
end
paint(active);
    function paint(id)
        for j = 1:numel(ids)
            if ids(j) == id
                buttons(j).FontColor = style.Primary;
                if sidebar
                    buttons(j).BackgroundColor = style.Primary;
                    buttons(j).FontColor = style.OnPrimary;
                else
                    lines(j).BackgroundColor = style.Primary;
                end
            else
                buttons(j).FontColor = style.Muted;
                buttons(j).BackgroundColor = style.Surface;
                if ~sidebar
                    lines(j).BackgroundColor = style.Surface;
                end
            end
        end
    end
    function selectPage(id)
        selected = obj.component(id);
        if isstruct(selected.UserData) && isfield(selected.UserData,"Reflow")
            selected.UserData.Reflow();
        end
        if canvas.UserData == id
            return
        end
        if ~sidebar && any(cellfun(@(signal) signal.Signal == "pageChanged",node.Signals))
            obj.Runtime.applyWorkspacePage(node.Id,id);
        end
        for j = 1:numel(ids)
            page = obj.component(ids(j));
            page.Visible = labkit.app.internal.native.NativeAdapterValues.onOff(ids(j) == id);
        end
        canvas.UserData = id;
        paint(id);
    end
end
