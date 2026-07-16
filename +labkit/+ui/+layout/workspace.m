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
%       logPanel nodes in display order. Default: {}.
%
% Outputs:
%   layout - Scalar workspace node with kind, id, props, children, and slots
%       fields.
%
% Description:
%   workspace defines the app's right-hand content area. The workbench assigns
%   rows and sizing from the child types; apps choose only the semantic content
%   and order.
%
% Example:
%   preview = labkit.ui.layout.workspace("workspace", "Preview", { ...
%       labkit.ui.layout.previewArea("image", "Image")});
%   assert(preview.kind == "workspace")
%
% See also labkit.ui.layout.previewArea, labkit.ui.layout.workbench

    if nargin < 3
        children = {};
    end
    props = optionStruct(varargin);
    props.title = char(string(titleText));
    layout = makeLayoutNode('workspace', id, props, children, struct());
end
