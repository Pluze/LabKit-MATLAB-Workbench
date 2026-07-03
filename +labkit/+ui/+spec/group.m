function spec = group(id, titleText, children, varargin)
%GROUP Create a grouped UI spec.
%
% App-facing contract:
%   spec = labkit.ui.spec.group(id, title, children, opts...)
%
% Inputs:
%   id - globally unique group id.
%   titleText - optional group title. Use "" for untitled inline groups.
%   children - cell row vector of semantic child specs.
%   opts - group options. layout may be "auto", "actions", "form",
%       "inline", or "grid". The default "auto" uses action layout when all
%       children are actions and form layout otherwise.
%
% Output:
%   spec - scalar data-only UI spec struct.

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
    spec = makeSpec('group', id, props, children, struct());
end
