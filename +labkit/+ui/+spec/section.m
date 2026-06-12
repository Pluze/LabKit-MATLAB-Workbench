function spec = section(id, titleText, children, varargin)
%SECTION Create a titled control-section spec.
%
% App-facing contract:
%   spec = labkit.ui.spec.section(id, title, children, opts...)
%
% Inputs:
%   id - globally unique section id.
%   titleText - section title.
%   children - cell row vector of control specs.
%   opts - app-neutral section options such as height.
%
% Output:
%   spec - scalar data-only UI spec struct.

    if nargin < 3
        children = {};
    end
    props = optionStruct(varargin);
    props.title = char(string(titleText));
    spec = makeSpec('section', id, props, children, struct());
end
