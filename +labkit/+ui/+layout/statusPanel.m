function layout = statusPanel(id, titleText, varargin)
%STATUSPANEL Create a read-only status/details panel layout node.
%
% App-facing contract:
%   layout = labkit.ui.layout.statusPanel(id, title, "value", lines)
%
% Inputs:
%   id - globally unique status panel id.
%   titleText - status panel title.
%   value - initial text or cellstr, default ''. Use app-level usage for
%       static first-page workflow instructions.
%   Concrete text-panel sizing is owned by the framework.
%
% Output:
%   layout - scalar data-only UI layout struct.

    props = optionStruct(varargin);
    props.title = char(string(titleText));
    layout = makeLayoutNode('statusPanel', id, props, {}, struct());
end
