function layout = section(id, titleText, children, varargin)
%SECTION Create a titled control-section layout node.
%
% App-facing contract:
%   layout = labkit.ui.layout.section(id, title, children, opts...)
%
% Inputs:
%   id - globally unique section id.
%   titleText - section title.
%   children - cell row vector of control layout nodes.
%   Apps may declare section order and contained controls. Concrete layout
%       such as height, spacing, padding, and chrome is owned by the framework.
%
% Output:
%   layout - scalar data-only UI layout struct.

    if nargin < 3
        children = {};
    end
    props = optionStruct(varargin);
    props.title = char(string(titleText));
    layout = makeLayoutNode('section', id, props, children, struct());
end
