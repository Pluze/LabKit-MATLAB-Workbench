function spec = tab(id, titleText, children, varargin)
%TAB Create a LabKit control-tab spec.
%
% App-facing contract:
%   spec = labkit.ui.spec.tab(id, title, children, opts...)
%
% Inputs:
%   id - globally unique tab id.
%   titleText - tab title shown in the control pane.
%   children - cell row vector of section specs.
%   opts - app-neutral tab options.
%
% Output:
%   spec - scalar data-only UI spec struct.

    if nargin < 3
        children = {};
    end
    props = optionStruct(varargin);
    props.title = char(string(titleText));
    spec = makeSpec('tab', id, props, children, struct());
end
