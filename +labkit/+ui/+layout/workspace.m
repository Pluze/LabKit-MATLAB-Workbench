function layout = workspace(id, titleText, children, varargin)
%WORKSPACE Create a right-side LabKit workbench workspace layout node.
%
% Usage:
%   layout = labkit.ui.layout.workspace(id, titleText, children)
%
% Inputs:
%   id - Text scalar used to identify the workspace. It must be a valid MATLAB
%       variable name and unique within the workbench.
%   titleText - Text displayed above the right-side workspace.
%   children - Cell row vector of previewArea, resultTable, statusPanel, or
%       logPanel nodes in display order. To expose multiple user-selectable
%       workspace pages, supply two or more tab nodes instead. Default: {}.
%
% Outputs:
%   layout - Scalar workspace node with kind, id, props, children, and slots
%       fields.
%
% Description:
%   workspace defines the app's right-hand content area. Direct panel children
%   form one vertical workspace. Two or more tab children form user-selectable
%   workspace pages. The workbench assigns rows, page selection, and sizing;
%   apps choose only semantic content and order.
%
% Errors:
%   labkit:ui:layout:InvalidId, InvalidOptions, or InvalidOptionName - id or
%   Name-value syntax is malformed.
%   labkit:ui:layout:InvalidChildren - children is not a cell row of scalar
%   layout nodes. Unsupported workspace child kinds are rejected at launch.
%
% Example:
%   preview = labkit.ui.layout.workspace("workspace", "Preview", { ...
%       labkit.ui.layout.previewArea("image", "Image")});
%   assert(preview.kind == "workspace")
%
% See also labkit.ui.layout.tab,
%   labkit.ui.layout.previewArea,
%   labkit.ui.layout.workbench

    if nargin < 3
        children = {};
    end
    props = optionStruct(varargin);
    props.title = char(string(titleText));
    layout = makeLayoutNode('workspace', id, props, children, struct());
end
