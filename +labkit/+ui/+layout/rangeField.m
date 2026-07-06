function layout = rangeField(id, labelText, varargin)
%RANGEFIELD Create a paired start/end or min/max field layout node.
%
% App-facing contract:
%   layout = labkit.ui.layout.rangeField(id, label, "value", [lo hi], ...)
%
% Inputs:
%   id - globally unique range id.
%   labelText - range label.
%   value - two-element numeric range value, optional.
%   limits, unit, tooltip, onChange - optional app-neutral props.
%
% Output:
%   layout - scalar data-only UI layout struct.

    props = optionStruct(varargin);
    props.label = char(string(labelText));
    layout = makeLayoutNode('rangeField', id, props, {}, struct());
end
