function node = field(id, varargin)
%FIELD Add a text, numeric, choice, or logical input field.
%
% Usage:
%   node = labkit.app.layout.field(id, Name=Value)
%
% Description:
%   Declares one bound or event-driven scalar input field.
%
% Inputs:
%   id - Unique MATLAB identifier for the layout target.
%
% Options:
%   Label - Display text. Default: id.
%   Kind - "text", "numeric", "choice", "logical", or "readonly".
%       Readonly fields render as compact, selectable text that wraps and
%       grows with its current value and available width. Default: "text".
%   Value - Initial value. Default: [].
%   Choices - Text row for choice fields. Default: strings(1,0).
%   Limits - Increasing finite numeric 1-by-2 row. Default: [].
%   Step - Positive numeric scalar. Default: [].
%   Bind - Project or session field path. Default: "".
%   ValueDisplayFormat - MATLAB numeric display format. Default: "".
%   Enabled - Initial logical enabled state. Default: true.
%   OnValueChanged - Scalar callback
%       state = callback(state,value,context). Default: [].
%   Every non-readonly field must declare Bind or OnValueChanged.
%
% Outputs:
%   node - Immutable internal layout node accepted by layout containers.
%
% Errors:
%   Throws labkit:app:contract:* for invalid IDs, options, handlers, or an
%   editable field with no declared state or callback owner.
%
% Typical Call:
%   node = labkit.app.layout.field("gain", Kind="numeric", ...
%       Bind="project.parameters.gain");
%
% See also labkit.app.layout.rangeField, labkit.app.layout.slider
node = labkit.app.internal.contract.LayoutNode.field(id, varargin{:});
end
