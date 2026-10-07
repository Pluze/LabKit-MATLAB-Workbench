classdef (Hidden, Sealed) AxesNavigation
    % Native wheel ownership, visible-target routing and explicit dual-Y choice.
    methods (Static)
        function install(ax)
            labkit.app.internal.native.AxesNavigation.installRestore(ax);
            interactions=ax.Interactions;
            keep=arrayfun(@(v) ~contains(lower(string(class(v))),"zoom"),interactions);
            if isempty(interactions)
                ax.Interactions=[panInteraction,dataTipInteraction];
            elseif ~all(keep)
                ax.Interactions=interactions(keep);
            end
            menu=ax.ContextMenu;
            if isempty(menu)||~isgraphics(menu),menu=uicontextmenu(ancestor(ax,'figure'));ax.ContextMenu=menu;end
            dual=numel(ax.YAxis)==2;
            existing=findall(menu,'Tag','labkitWheelMenu');
            if isempty(existing)
                existing=uimenu(menu,Text="Mouse wheel zoom",Tag="labkitWheelMenu");
            end
            if ~isappdata(ax,'labkitWheelMode')
                mode="xy";
                if isappdata(ax,'labkitPreviewScrollZoomAxes'),mode=string(getappdata(ax,'labkitPreviewScrollZoomAxes'));end
                if dual,mode="x";end
                setappdata(ax,'labkitWheelMode',mode);
            end
            modes=["xy","x","y"];labels=["X + Y","X only","Y only"];
            if dual,modes=["x","left","right","both"];labels=["X only","Left Y only","Right Y only","X + both Y axes"];end
            delete(existing.Children);
            for k=1:numel(modes)
                uimenu(existing,Text=labels(k),Tag="labkitWheelMode_"+modes(k), ...
                    Checked=string(getappdata(ax,'labkitWheelMode'))==modes(k), ...
                    MenuSelectedFcn=@(~,~) labkit.app.internal.native.AxesNavigation.select(ax,modes(k)));
            end
            labkit.app.internal.native.AxesNavigation.select(ax,string(getappdata(ax,'labkitWheelMode')));
        end
        function select(ax,mode)
            setappdata(ax,'labkitWheelMode',string(mode));
            menu=findall(ax.ContextMenu,'Tag','labkitWheelMenu');
            for child=reshape(menu.Children,1,[])
                child.Checked=string(child.Tag)=="labkitWheelMode_"+mode;
                if string(child.Checked)=="on",menu.Text="Mouse wheel: "+child.Text;end
            end
        end
        function changed=wheel(ax,point,count)
            mode="xy";
            if isappdata(ax,'labkitWheelMode'),mode=string(getappdata(ax,'labkitWheelMode'));
            elseif isappdata(ax,'labkitPreviewScrollZoomAxes'),mode=string(getappdata(ax,'labkitPreviewScrollZoomAxes'));end
            if numel(ax.YAxis)~=2 || any(mode==["x","y","xy"])
                changed=zoomAxesAtPoint(ax,point,count,"ZoomAxes",mode);return;
            end
            side=string(ax.YAxisLocation);cleanup=onCleanup(@() yyaxis(ax,side));
            bounds=ax.YLim;anchor=point(2);
            if ax.YScale=="log",bounds=log(bounds);anchor=log(anchor);end
            fraction=(anchor-bounds(1))/diff(bounds);changed=false;
            if mode=="both",changed=zoomAxesAtPoint(ax,point,count,"ZoomAxes","x");end
            sides=["left","right"];if mode~="both",sides=mode;end
            for selected=sides
                yyaxis(ax,selected);limits=ax.YLim;
                if ax.YScale=="log",limits=log(limits);end
                y=limits(1)+fraction*diff(limits);
                if ax.YScale=="log",y=exp(y);end
                changed=zoomAxesAtPoint(ax,[point(1),y],count,"ZoomAxes","y")||changed;
            end
        end
        function visible=isVisible(ax)
            visible=true;node=ax;
            % A hidden figure cannot receive input; skip it for bounded GUI tests.
            while isgraphics(node) && ~isa(node,'matlab.ui.Figure')
                if isprop(node,'Visible') && string(node.Visible)=="off",visible=false;return;end
                parent=node.Parent;
                if isa(node,'matlab.ui.container.Tab') && parent.SelectedTab~=node,visible=false;return;end
                node=parent;
            end
        end
        function installRestore(ax)
            toolbar = ax.Toolbar;
            if isempty(toolbar), return; end
            % Default toolbar buttons are created lazily by MATLAB.
            if isempty(toolbar.Children)
                toolbar = axtoolbar(ax, 'default');
            end
            buttons = findall(toolbar, 'Icon', 'restoreview');
            for button = reshape(buttons, 1, [])
                button.ButtonPushedFcn = @(~, ~) ...
                    labkit.app.internal.native.AxesNavigation.refit(ax);
            end
        end
        function refit(axes,freeze)
            if nargin<2,freeze=false;end
            for ax=reshape(axes,1,[])
                ax.XLimMode='auto';
                for ruler=reshape(ax.YAxis,1,[]),ruler.LimitsMode='auto';end
                if freeze
                    ax.XLim=ax.XLim;
                    for ruler=reshape(ax.YAxis,1,[]),ruler.Limits=ruler.Limits;end
                end
            end
        end
    end
end
