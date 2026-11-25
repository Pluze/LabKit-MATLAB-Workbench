function frame = installPageNavigation(obj, node, parent)
% A page strip and a single shared canvas for titled workspaces.
style = obj.Appearance;
pages = obj.nodes(node.PageIds);
ids = string({pages.Id});
active = node.InitialPage;
if active == ""
    active = ids(1);
end
frame = uigridlayout(parent,[1 1],Padding=[0 0 0 0],BackgroundColor=style.Surface);
bar = uigridlayout(obj.Header,[2 numel(ids)+1],RowHeight={'1x',2}, ...
    ColumnWidth=[repmat({'fit'},1,numel(ids)),{'1x'}],Padding=[16 0 0 0], ...
    RowSpacing=0,ColumnSpacing=6,BackgroundColor=style.Surface);
bar.Layout.Row = 1;
bar.Layout.Column = numel(obj.Header.ColumnWidth) - ...
    double(isnumeric(obj.Header.ColumnWidth{end}));
canvas = frame;
canvas.UserData = active;
obj.Layouts(char(node.Id)) = canvas;
buttons = gobjects(size(ids));
lines = gobjects(size(ids));
for i = 1:numel(ids)
    buttons(i) = uibutton(bar,Text=pages(i).Configuration.Title,Tag=ids(i)+".navigate", ...
        FontWeight="bold",BackgroundColor=style.Surface,Interruptible="off",BusyAction="cancel", ...
        ButtonPushedFcn=@(~,~) ...
        obj.runUserInput(@() selectPage(ids(i))));
    buttons(i).Layout.Row = 1;
    buttons(i).Layout.Column = i;
    lines(i) = uilabel(bar,Text="");
    lines(i).Layout.Row = 2;
    lines(i).Layout.Column = i;
end
paint(active);
    function paint(id)
        for j = 1:numel(ids)
            if ids(j) == id
                buttons(j).FontColor = style.Primary;
                lines(j).BackgroundColor = style.Primary;
            else
                buttons(j).FontColor = style.Muted;
                lines(j).BackgroundColor = style.Surface;
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
        if any(cellfun(@(signal) signal.Signal == "pageChanged",node.Signals))
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
