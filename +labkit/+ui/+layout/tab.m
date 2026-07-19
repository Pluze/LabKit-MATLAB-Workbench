function layout = tab(id, titleText, children, varargin)
%TAB Create a LabKit control or workspace tab layout node.
%
% Usage:
%   layout = labkit.ui.layout.tab(id, titleText, children)
%
% Inputs:
%   id - Text scalar used to identify the tab. It must be a valid MATLAB
%       variable name and unique within the workbench.
%   titleText - Text displayed on the tab.
%   children - Cell row vector in display order. A control tab contains section
%       nodes. A tab placed directly in workspace contains previewArea,
%       resultTable, statusPanel, or logPanel nodes. Default: {}.
%
% Outputs:
%   layout - Scalar tab node with kind, id, props, children, and slots fields.
%
% Description:
%   tab defines one selectable page. Add it to the controlTabs cell array for a
%   left-side control page, or place two or more tab nodes directly in a
%   workspace for user-selectable right-side pages. Runtime owns the native tab
%   group, selection behavior, and page geometry.
%
% Errors:
%   labkit:ui:layout:InvalidId, InvalidOptions, or InvalidOptionName - id or
%   Name-value syntax is malformed.
%   labkit:ui:layout:InvalidChildren - children is not a cell row of scalar
%   layout nodes. Child kinds and empty-section rules are checked at launch.
%
% Example:
%   setupTab = labkit.ui.layout.tab("setup", "Setup", { ...
%       labkit.ui.layout.section("inputs", "Inputs", { ...
%       labkit.ui.layout.field("name", "Name")})});
%   assert(setupTab.kind == "tab")
%
% See also labkit.ui.layout.section,
%   labkit.ui.layout.workspace,
%   labkit.ui.layout.workbench

    if nargin < 3
        children = {};
    end
    props = optionStruct(varargin);
    props.title = char(string(titleText));
    layout = makeLayoutNode('tab', id, props, children, struct());
end
