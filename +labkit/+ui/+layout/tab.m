function layout = tab(id, titleText, children, varargin)
%TAB Create a LabKit control-tab layout node.
%
% App-facing contract:
%   layout = labkit.ui.layout.tab(id, title, children, opts...)
%
% Inputs:
%   id - globally unique tab id.
%   titleText - tab title shown in the control pane.
%   children - cell row vector of section layout nodes.
%   opts - app-neutral tab options.
%
% Output:
%   layout - scalar data-only UI layout struct.

    if nargin < 3
        children = {};
    end
    props = optionStruct(varargin);
    props.title = char(string(titleText));
    layout = makeLayoutNode('tab', id, props, children, struct());
end
