function frame = installPageNavigation(obj, node, parent, pages)
% A page strip and a single shared canvas for titled workspaces.
style = obj.Appearance;
policy = labkit.app.internal.native.NativeAdapterValues.layoutPolicy();
gap = policy.ButtonGap;
sidebar = node.Kind == "workbench";
if ~sidebar
    pages = obj.nodes(node.PageIds);
end
ids = string({pages.Id});
active = ids(1);
if ~sidebar && node.InitialPage ~= ""
    active = node.InitialPage;
end
frame = uipanel(parent, BorderType="none", AutoResizeChildren="off", BackgroundColor=style.Surface);
selector = [];
if sidebar
    columns = min(2,numel(ids));
    rows = ceil(numel(ids)/columns);
    parent.RowHeight = {32*rows+gap*(rows-1),'1x'};
    bar = uigridlayout(parent,[rows columns],RowHeight=repmat({32},1,rows), ...
        Padding=[0 0 0 0],ColumnSpacing=gap,RowSpacing=gap,BackgroundColor=parent.BackgroundColor);
    bar.Layout.Row = 1;
    frame.Layout.Row = 2;
    frame.BackgroundColor = parent.BackgroundColor;
else
    columns = numel(ids);
    host = uipanel(obj.Header,BorderType="none",BackgroundColor=style.Surface,AutoResizeChildren="off");
    host.Layout.Row = 1;
    host.Layout.Column = find(strcmp(obj.Header.ColumnWidth,'1x'),1);
    layers = uigridlayout(host,[1 1],Padding=[0 0 0 0],BackgroundColor=style.Surface);
    bar = uigridlayout(layers,[1 columns+1],RowHeight={'1x'}, ...
        ColumnWidth=[repmat({'fit'},1,columns),{'1x'}],Padding=[8 0 0 0], ...
        RowSpacing=0,ColumnSpacing=gap,BackgroundColor=style.Surface);
    bar.Layout.Row = 1;
    bar.Layout.Column = 1;
    titles = arrayfun(@(page) string(page.Configuration.Title),pages);
    selector = uidropdown(layers,Items=titles,ItemsData=ids,Value=active, ...
        Tag=node.Id+".choosePage",Tooltip="Choose a workspace view", ...
        ValueChangedFcn=@(source,~) obj.runUserInput(@() selectPage(source.Value)));
    selector.Layout.Row = 1;
    selector.Layout.Column = 1;
    requiredWidth = sum(8*strlength(titles)+24) + gap*(columns-1) + 8;
    actionWidth = 0;
    root = obj.owningNode(node.Id);
    if root.Configuration.HeaderAction ~= ""
        action = obj.node(root.Configuration.HeaderAction);
        actionWidth = 8*strlength(action.Configuration.Label)+28;
    end
    reservedWidth = 48 + 9*strlength(obj.DisplayName) + actionWidth;
    split = obj.WorkbenchWorkspace.Parent;
    host.SizeChangedFcn = @(source,~) fitNavigation(min(source.InnerPosition(3), availableWidth()));
    obj.Layouts(char(node.Id)) = frame;
end
canvas = frame;
canvas.UserData = active;
buttons = gobjects(size(ids));
for i = 1:numel(ids)
    buttons(i) = uibutton(bar,Text=pages(i).Configuration.Title,Tag=ids(i)+".navigate", ...
        FontWeight="bold",BackgroundColor=style.Surface,Interruptible="off",BusyAction="cancel", ...
        ButtonPushedFcn=@(~,~) ...
        obj.runUserInput(@() selectPage(ids(i))));
    buttons(i).Layout.Row = ceil(i/columns);
    buttons(i).Layout.Column = mod(i-1,columns)+1;
end
paint(active);
if ~sidebar
    fitNavigation(availableWidth());
end
    function width = availableWidth()
        width = obj.Figure.Position(3) - split.ColumnWidth{1} - split.ColumnWidth{2} - reservedWidth;
    end
    function fitNavigation(width)
        % Keep long view lists accessible beside the header action at every width.
        compact = numel(ids) > 3 || width < requiredWidth;
        if strcmp(selector.Visible, labkit.app.internal.native.NativeAdapterValues.onOff(compact)) && ...
                strcmp(bar.Visible, labkit.app.internal.native.NativeAdapterValues.onOff(~compact))
            return
        end
        selector.Visible = labkit.app.internal.native.NativeAdapterValues.onOff(compact);
        bar.Visible = labkit.app.internal.native.NativeAdapterValues.onOff(~compact);
    end
    function paint(id)
        if ~isempty(selector)
            selector.Value = id;
        end
        for j = 1:numel(ids)
            if ids(j) == id
                buttons(j).FontColor = style.Primary;
                if sidebar
                    buttons(j).BackgroundColor = style.Primary;
                    buttons(j).FontColor = style.OnPrimary;
                else
                    buttons(j).BackgroundColor = style.Paper;
                end
            else
                buttons(j).FontColor = style.Muted;
                buttons(j).BackgroundColor = style.Surface;
            end
        end
    end
    function selectPage(id)
        if canvas.UserData == id
            return
        end
        previous = obj.component(canvas.UserData);
        selected = obj.component(id);
        if isstruct(selected.UserData) && isfield(selected.UserData,"Reflow")
            selected.UserData.Reflow();
        end
        if ~sidebar && any(cellfun(@(signal) signal.Signal == "pageChanged",node.Signals))
            obj.Runtime.applyWorkspacePage(node.Id,id);
        end
        previous.Visible = "off";
        previous.Units = "pixels";
        selected.Units = "normalized";
        selected.Position = [0 0 1 1];
        selected.Visible = "on";
        canvas.UserData = id;
        paint(id);
        readouts = findall(selected, 'Type', 'uitextarea');
        for readout = reshape(readouts, 1, [])
            obj.updateReadonlyHeight(readout, readout.Value);
        end
    end
end
