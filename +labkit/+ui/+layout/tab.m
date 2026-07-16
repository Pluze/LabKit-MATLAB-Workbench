function layout = tab(id, titleText, children, varargin)
%TAB Create a LabKit control-tab layout node.
%
% Usage:
%   layout = labkit.ui.layout.tab(id, titleText, children)
%
% Inputs:
%   id - Text scalar used to identify the tab. It must be a valid MATLAB
%       variable name and unique within the workbench.
%   titleText - Text displayed on the tab in the control pane.
%   children - Cell row vector of section nodes in display order. Default: {}.
%       Each section must contain at least one control before launch.
%
% Outputs:
%   layout - Scalar tab node with kind, id, props, children, and slots fields.
%
% Description:
%   tab defines one page in the left control pane. Add the resulting node to the
%   controlTabs cell array of a workbench.
%
% Example:
%   setupTab = labkit.ui.layout.tab("setup", "Setup", { ...
%       labkit.ui.layout.section("inputs", "Inputs", { ...
%       labkit.ui.layout.field("name", "Name")})});
%   assert(setupTab.kind == "tab")
%
% See also labkit.ui.layout.section, labkit.ui.layout.workbench

    if nargin < 3
        children = {};
    end
    props = optionStruct(varargin);
    props.title = char(string(titleText));
    layout = makeLayoutNode('tab', id, props, children, struct());
end
