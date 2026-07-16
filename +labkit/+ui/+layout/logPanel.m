function layout = logPanel(id, titleText, varargin)
%LOGPANEL Create a read-only log panel layout node.
%
% Usage:
%   layout = labkit.ui.layout.logPanel(id, titleText)
%   layout = labkit.ui.layout.logPanel(id, titleText, "value", lines)
%
% Inputs:
%   id - Text scalar used to identify the log. It must be a valid MATLAB
%       variable name and unique within the workbench.
%   titleText - Text displayed in the panel title.
%
% Name-Value Arguments:
%   value - Initial log lines as text, a string array, or cellstr. Default:
%       {'Ready.'}.
%
% Outputs:
%   layout - Scalar logPanel node with kind, id, props, children, and slots
%       fields.
%
% Description:
%   logPanel displays changing workflow or diagnostic messages in a read-only
%   text area. It follows the newest line by default. Users can pause or resume
%   automatic scrolling with the visible button or the context menu. Use the
%   workbench usage option for static instructions that should always remain
%   visible.
%
% Example:
%   logView = labkit.ui.layout.logPanel( ...
%       "workflowLog", "Log", "value", ["Ready."; "Waiting for files."]);
%   assert(logView.kind == "logPanel")
%
% See also labkit.ui.layout.statusPanel, labkit.ui.layout.workbench

    props = optionStruct(varargin);
    props.title = char(string(titleText));
    layout = makeLayoutNode('logPanel', id, props, {}, struct());
end
