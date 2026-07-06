function layout = group(id, titleText, children, varargin)
%GROUP Create a grouped UI layout.
%
% App-facing contract:
%   layout = labkit.ui.layout.group(id, title, children, opts...)
%
% Inputs:
%   id - globally unique group id.
%   titleText - optional group title. Use "" for untitled inline groups.
%   children - cell row vector of semantic child layout nodes.
%   opts - group options. layout may be "auto", "actions", "form",
%       "inline", or "grid". The default "auto" uses action layout when all
%       children are actions and form layout otherwise.
%
% Output:
%   layout - scalar data-only UI layout struct.

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
