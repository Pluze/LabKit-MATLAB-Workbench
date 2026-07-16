function layout = group(id, titleText, children, varargin)
%GROUP Create a grouped UI layout.
%
% Usage:
%   layout = labkit.ui.layout.group(id, titleText, children)
%   layout = labkit.ui.layout.group(id, titleText, children, "layout", mode)
%
% Inputs:
%   id - Text scalar used to identify the group. It must be a valid MATLAB
%       variable name and unique within the workbench.
%   titleText - Optional group title. Use "" for an untitled group. Default:
%       "".
%   children - Nonempty cell row vector containing field, rangeField, panner,
%       action, or nested group nodes. Default: {}. An empty group can be
%       constructed but is rejected when the workbench is launched.
%
% Name-Value Arguments:
%   layout - Group presentation mode: "auto", "actions", "form", "inline",
%       or "grid". "auto" uses an action-button layout when every child is an
%       action and a form layout otherwise. "actions" requires every child to
%       be an action. The other modes currently use the standard form
%       presentation. Default: "auto".
%
% Outputs:
%   layout - Scalar group node with kind, id, props, children, and slots fields.
%
% Description:
%   group keeps related controls together inside one section. It is useful for
%   a row or block of commands and for a labeled subsection of fields. Concrete
%   row heights, spacing, and column widths are selected by the workbench.
%
% Example:
%   commands = labkit.ui.layout.group("commands", "Commands", { ...
%       labkit.ui.layout.action("run", "Run", []), ...
%       labkit.ui.layout.action("reset", "Reset", [])});
%   assert(numel(commands.children) == 2)
%
% See also labkit.ui.layout.action, labkit.ui.layout.section

    if nargin < 2
        titleText = "";
    end
    if nargin < 3
        children = {};
    end
    props = optionStruct(varargin);
    props.title = char(string(titleText));
    if ~isfield(props, 'layout')
        props.layout = 'auto';
    end
    layout = makeLayoutNode('group', id, props, children, struct());
end
