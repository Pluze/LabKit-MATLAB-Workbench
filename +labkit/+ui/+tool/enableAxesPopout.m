function enableAxesPopout(ax)
%ENABLEAXESPOPOUT Add a context-menu action to copy an axes to a figure.
%
% App-facing contract:
%   labkit.ui.tool.enableAxesPopout(ax)
%
% Inputs:
%   ax - UI axes or axes handle to receive the "Open axes in new figure"
%       context action.
%
% Output:
%   No return value. Mutates ax and graphics children in place. Safe to call
%       after redraws.

    if isempty(ax) || ~isvalid(ax)
        return;
    end
    menu = ax.ContextMenu;
    if isappdata(ax, 'labkitAxesPopoutEnabled') && ...
            getappdata(ax, 'labkitAxesPopoutEnabled') && ...
            ~isempty(menu) && isvalid(menu) && ...
            ~isempty(findall(menu, 'Type', 'uimenu', 'Tag', 'labkitAxesPopoutMenu'))
        attachMenuToAxesChildren(ax, menu);
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
            'MenuSelectedFcn', @(~,~) labkit.ui.tool.popoutAxes(ax));
    end
    attachMenuToAxesChildren(ax, menu);
    installChildrenListener(ax, menu);
    setappdata(ax, 'labkitAxesPopoutEnabled', true);
end

function installChildrenListener(ax, menu)
    if isappdata(ax, 'labkitAxesPopoutChildrenListener')
        listener = getappdata(ax, 'labkitAxesPopoutChildrenListener');
        if ~isempty(listener)
            return;
        end
    end
    try
        listener = addlistener(ax, 'Children', 'PostSet', ...
            @(~,~) attachMenuToAxesChildren(ax, menu));
        setappdata(ax, 'labkitAxesPopoutChildrenListener', listener);
    catch
    end
end

function attachMenuToAxesChildren(ax, menu)
    if isempty(ax) || ~isvalid(ax) || isempty(menu) || ~isvalid(menu)
        return;
    end
    children = ax.Children;
    for k = 1:numel(children)
        child = children(k);
        if ~isvalid(child) || ~isprop(child, 'ContextMenu')
            continue;
        end
        if isempty(child.ContextMenu) || ~isvalid(child.ContextMenu)
            try
                child.ContextMenu = menu;
            catch
            end
        end
    end
end
