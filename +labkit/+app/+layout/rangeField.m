function node = rangeField(id, varargin)
%RANGEFIELD Add an input for a numeric lower and upper bound.
%
% Usage:
%   node = labkit.app.layout.rangeField(id, Name=Value)
%
% Description:
%   Declares one two-value numeric range input.
%
% Inputs:
%   id - Unique MATLAB identifier for the layout target.
%
% Options:
%   Label - Display text. Default: id.
%   Value - Finite numeric 1-by-2 row. Default: [].
%   Limits - Increasing finite numeric 1-by-2 row. Default: [].
%   Enabled - Initial logical enabled state. Default: true.
%   Bind - Project or session field path. Default: "".
%   ValueChanged - StateHandler with Event="valueChange". Default: [].
%
% Outputs:
%   node - Immutable internal layout node accepted by layout containers.
%
% Errors:
%   Throws labkit:app:contract:* for invalid IDs, options, or handlers.
%
% Typical Call:
%   node = labkit.app.layout.rangeField("window", Limits=[0 10]);
%
% See also labkit.app.layout.field, labkit.app.layout.slider
node = labkit.app.internal.LayoutNode.rangeField(id, varargin{:});
end
