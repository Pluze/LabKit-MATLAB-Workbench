function layout = section(id, titleText, children, varargin)
%SECTION Create a titled control-section layout node.
%
% Usage:
%   layout = labkit.ui.layout.section(id, titleText, children)
%
% Inputs:
%   id - Text scalar used to identify the section. It must be a valid MATLAB
%       variable name and unique within the workbench.
%   titleText - Text displayed in the section header.
%   children - Cell row vector of field, rangeField, panner, action, group,
%       filePanel, resultTable, statusPanel, or logPanel nodes. Default: {}.
%       An empty section can be constructed but is rejected at launch.
%
% Outputs:
%   layout - Scalar section node with kind, id, props, children, and slots
%       fields.
%
% Description:
%   A section is the ordered block of controls shown within a control tab. Apps
%   choose the title, child controls, and their order; the workbench chooses the
%   concrete height, spacing, padding, and border presentation.
%
% Errors:
%   labkit:ui:layout:InvalidId, InvalidOptions, or InvalidOptionName - id or
%   Name-value syntax is malformed.
%   labkit:ui:layout:InvalidChildren - children is not a cell row of scalar
%   layout nodes. Empty or unsupported child sets are rejected at launch.
%
% Example:
%   inputs = labkit.ui.layout.section("inputs", "Inputs", { ...
%       labkit.ui.layout.field("sampleName", "Sample name")});
%   assert(inputs.kind == "section")
%
% See also labkit.ui.layout.tab, labkit.ui.layout.group

    if nargin < 3
        children = {};
    end
    props = optionStruct(varargin);
    props.title = char(string(titleText));
    layout = makeLayoutNode('section', id, props, children, struct());
end
