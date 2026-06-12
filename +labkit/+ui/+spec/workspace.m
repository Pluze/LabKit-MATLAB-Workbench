function spec = workspace(id, titleText, children, varargin)
%WORKSPACE Create a right-side LabKit workbench workspace spec.
%
% App-facing contract:
%   spec = labkit.ui.spec.workspace(id, title, children, opts...)
%
% Inputs:
%   id - globally unique workspace id.
%   titleText - workspace panel title.
%   children - cell row vector of workspace child specs, usually previewArea.
%   opts - app-neutral layout options such as row heights.
%
% Output:
%   spec - scalar data-only UI spec struct.

    if nargin < 3
        children = {};
    end
    props = optionStruct(varargin);
    props.title = char(string(titleText));
    spec = makeSpec('workspace', id, props, children, struct());
end
