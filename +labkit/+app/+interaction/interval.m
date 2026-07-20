function spec = interval(id, onChanged, varargin)
%INTERVAL Declare an editable one-dimensional plot interval.
%
% Usage:
%   spec = labkit.app.interaction.interval(id,onChanged,Name=Value)
%
% Description:
%   Creates the semantic declaration for a managed interval editor and its
%   optional typed scroll callback on one plot axis.
%
% Inputs:
%   id - Unique MATLAB identifier.
%   onChanged - Callback state = callback(state,range,context).
%
% Options:
%   Axis - Axis ID. Default: "main".
%   Style - Scalar visual-option struct. Default: struct().
%   Instruction - Scalar guidance text. Default: "".
%   ViewportPolicy - "preserve" or "fit". Default: "preserve".
%   OnScrolled - Optional callback state = callback(state,event,context),
%       where event is labkit.app.event.IntervalScroll. Default: [].
%
% Outputs:
%   spec - Immutable interaction declaration.
%
% Errors:
%   Throws labkit:app:contract:* for invalid values.
%
% Typical Call:
%   spec = labkit.app.interaction.interval("window",@changeWindow);
%
% See also labkit.app.layout.plotArea,
%   labkit.app.event.IntervalScroll
options = labkit.app.internal.OptionParser.parse( ...
    "labkit.app.interaction.interval", ...
    ["Axis", "Style", "Instruction", "ViewportPolicy", "OnScrolled"], ...
    varargin{:});
spec = labkit.app.internal.InteractionSpec("interval",id,onChanged,options);
end
