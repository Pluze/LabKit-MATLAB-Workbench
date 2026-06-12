function spec = rangeField(id, labelText, varargin)
%RANGEFIELD Create a paired start/end or min/max field spec.
%
% App-facing contract:
%   spec = labkit.ui.spec.rangeField(id, label, "value", [lo hi], ...)
%
% Inputs:
%   id - globally unique range id.
%   labelText - range label.
%   value - two-element numeric range value, optional.
%   limits, unit, tooltip, onChange - optional app-neutral props.
%
% Output:
%   spec - scalar data-only UI spec struct.

    props = optionStruct(varargin);
    props.label = char(string(labelText));
    spec = makeSpec('rangeField', id, props, {}, struct());
end
