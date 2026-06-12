function spec = actionGroup(id, children, varargin)
%ACTIONGROUP Create an app-command group spec.
%
% App-facing contract:
%   spec = labkit.ui.spec.actionGroup(id, children, opts...)
%
% Inputs:
%   id - globally unique group id.
%   children - cell row vector of action specs.
%   opts - group options such as orientation or enabled state.
%
% Output:
%   spec - scalar data-only UI spec struct.

    if nargin < 2
        children = {};
    end
    props = optionStruct(varargin);
    spec = makeSpec('actionGroup', id, props, children, struct());
end
