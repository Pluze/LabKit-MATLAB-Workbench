function layout = workspace(id, titleText, children, varargin)
%WORKSPACE Create a right-side LabKit workbench workspace layout node.
%
% App-facing contract:
%   layout = labkit.ui.layout.workspace(id, title, children, opts...)
%
% Inputs:
%   id - globally unique workspace id.
%   titleText - workspace panel title.
%   children - cell row vector of workspace child layout nodes, usually previewArea.
%   Concrete workspace row layout is owned by the framework.
%
% Output:
%   layout - scalar data-only UI layout struct.

    if nargin < 3
        children = {};
    end
    props = optionStruct(varargin);
    props.title = char(string(titleText));
    layout = makeLayoutNode('workspace', id, props, children, struct());
end
