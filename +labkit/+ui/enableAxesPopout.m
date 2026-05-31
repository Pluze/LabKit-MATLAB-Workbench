function enableAxesPopout(ax)
%ENABLEAXESPOPOUT Add a context-menu action to copy an axes to a figure.

    if isempty(ax) || ~isvalid(ax)
        return;
    end
    menu = ax.ContextMenu;
    if isappdata(ax, 'labkitAxesPopoutEnabled') && ...
            getappdata(ax, 'labkitAxesPopoutEnabled') && ...
            ~isempty(menu) && isvalid(menu) && ...
            ~isempty(findall(menu, 'Type', 'uimenu', 'Tag', 'labkitAxesPopoutMenu'))
        return;
    end

    fig = ancestor(ax, 'figure');
    if isempty(fig)
        return;
    end

    if isempty(menu) || ~isvalid(menu)
        menu = uicontextmenu(fig);
        ax.ContextMenu = menu;
    end

    existing = findall(menu, 'Type', 'uimenu', 'Tag', 'labkitAxesPopoutMenu');
    if isempty(existing)
        uimenu(menu, ...
            'Text', 'Open axes in new figure', ...
            'Tag', 'labkitAxesPopoutMenu', ...
            'MenuSelectedFcn', @(~,~) labkit.ui.popoutAxes(ax));
    end
    setappdata(ax, 'labkitAxesPopoutEnabled', true);
end
