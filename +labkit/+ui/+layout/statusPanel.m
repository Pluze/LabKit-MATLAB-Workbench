function layout = statusPanel(id, titleText, varargin)
%STATUSPANEL Create a read-only status/details panel layout node.
%
% Usage:
%   layout = labkit.ui.layout.statusPanel(id, titleText)
%   layout = labkit.ui.layout.statusPanel(id, titleText, "value", lines)
%
% Inputs:
%   id - Text scalar used to identify the panel. It must be a valid MATLAB
%       variable name and unique within the workbench.
%   titleText - Text displayed in the panel title.
%
% Name-Value Arguments:
%   value - Initial details as text, a string array, or cellstr. Default: "".
%
% Outputs:
%   layout - Scalar statusPanel node with kind, id, props, children, and slots
%       fields.
%
% Description:
%   statusPanel shows read-only summaries or details that the presenter may
%   replace as app state changes. Unlike logPanel, it has no follow-latest
%   controls. Use the workbench usage option for static workflow instructions.
%
% Errors:
%   labkit:ui:layout:InvalidId, InvalidOptions, or InvalidOptionName - id or
%   Name-value syntax is malformed. Text conversion and graphics compatibility
%   of value are validated when the runtime builds the panel.
%
% Example:
%   status = labkit.ui.layout.statusPanel( ...
%       "selectionStatus", "Selection", "value", "No file selected");
%   assert(status.kind == "statusPanel")
%
% See also labkit.ui.layout.logPanel, labkit.ui.layout.resultTable

    props = optionStruct(varargin);
    props.title = char(string(titleText));
    layout = makeLayoutNode('statusPanel', id, props, {}, struct());
end
