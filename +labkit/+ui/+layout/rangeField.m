function layout = rangeField(id, labelText, varargin)
%RANGEFIELD Create a paired start/end or min/max field layout node.
%
% Usage:
%   layout = labkit.ui.layout.rangeField(id, labelText)
%   layout = labkit.ui.layout.rangeField(id, labelText, Name=Value)
%
% Inputs:
%   id - Text scalar used to identify the range. It must be a valid MATLAB
%       variable name and unique within the workbench.
%   labelText - Text displayed beside the two numeric fields.
%
% Name-Value Arguments:
%   value - Two-element numeric value [first second]. Default: [0 0].
%   limits - Two-element limits applied independently to both numeric fields.
%   onChange - Function handle called as onChange(control,event). event.value
%       contains the current two-element range.
%   debounceMs - Delay before onChange runs, in milliseconds. Default: 500.
%       Use 0 for immediate dispatch.
%   Bind - Runtime V2 path to a two-element project or session value.
%   Event - Action ID dispatched after a bound value is written. Requires Bind.
%
% Outputs:
%   layout - Scalar rangeField node with kind, id, props, children, and slots
%       fields.
%
% Description:
%   rangeField renders two adjacent numeric edit fields as one semantic value.
%   Both edits report the complete two-element value. Runtime construction
%   rejects values that do not contain exactly two elements.
%
% Example:
%   window = labkit.ui.layout.rangeField( ...
%       "timeWindow", "Time window (s)", "value", [0 5], "limits", [0 Inf]);
%   assert(isequal(window.props.value, [0 5]))
%
% See also labkit.ui.layout.field, labkit.ui.layout.panner

    props = optionStruct(varargin);
    props.label = char(string(labelText));
    layout = makeLayoutNode('rangeField', id, props, {}, struct());
end
