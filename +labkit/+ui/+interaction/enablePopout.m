function enablePopout(ax)
%ENABLEPOPOUT Add a standalone-figure action to an axes context menu.
%
% Usage:
%   labkit.ui.interaction.enablePopout(ax)
%
% Inputs:
%   ax - MATLAB axes or uiaxes handle that receives an "Open axes in new
%       figure" context-menu item. Empty or invalid handles are ignored.
%
% Outputs:
%   None.
%
% Description:
%   The menu copies the current axes content, limits, labels, colors, and
%   visible legend entries into a normal MATLAB figure with publication and
%   export tools. Existing axes context-menu items are preserved. Children
%   without their own context menu inherit the axes menu, including children
%   added after this call. Repeated calls do not add duplicate menu items.
%
% Failure Behavior:
%   Empty or invalid handles are ignored. Errors raised while MATLAB creates
%   the context menu, copies graphics, or opens the standalone figure are not
%   caught and propagate from the originating graphics operation.
%
% Typical Call:
%   plot(ax, time, signal);
%   labkit.ui.interaction.enablePopout(ax);
%
% See also labkit.ui.layout.previewArea

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
            'MenuSelectedFcn', @(~,~) popoutAxes(ax));
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
