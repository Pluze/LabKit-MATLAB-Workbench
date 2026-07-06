function layout = usagePanel(id, titleText, varargin)
%USAGEPANEL Create a read-only workflow usage panel layout node.
%
% App-facing contract:
%   layout = labkit.ui.layout.usagePanel(id, title, "value", lines)
%
% Inputs:
%   id - globally unique usage panel id.
%   titleText - usage/help panel title.
%   value - usage lines as text or cellstr, default ''.
%   Prefer app-level usage on labkit.ui.layout.workbench so the framework places
%       first-page workflow instructions consistently.
%   Concrete usage-panel sizing is owned by the framework.
%
% Output:
%   layout - scalar data-only UI layout struct.

    props = optionStruct(varargin);
    props.title = char(string(titleText));
    layout = makeLayoutNode('usagePanel', id, props, {}, struct());
end
