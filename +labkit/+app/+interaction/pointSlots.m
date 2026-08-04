function spec = pointSlots(id, onChanged, varargin)
%POINTSLOTS Declare a fixed set of editable labeled point positions.
%
% Usage:
%   spec = labkit.app.interaction.pointSlots(id,onChanged,Name=Value)
%
% Description:
%   Creates the semantic declaration for a fixed, labeled set of editable
%   points whose structured value is committed by the runtime.
%
% Inputs:
%   id - Unique MATLAB identifier.
%   onChanged - Callback state = callback(state,value,context).
%
% Options:
%   Axis - Axis ID. Default: "main".
%   Style - Scalar visual-option struct. Default: struct().
%   Instruction - Scalar guidance text. Default: "".
%   ViewportPolicy - "preserve" or "fit". Default: "preserve".
%
% Outputs:
%   spec - Immutable interaction declaration.
%
% Errors:
%   Throws labkit:app:contract:* for invalid values.
%
% Typical Call:
%   spec = labkit.app.interaction.pointSlots("markers",@changeMarkers);
%
% See also labkit.app.layout.plotArea
options = labkit.app.internal.contract.OptionParser.parse( ...
    "labkit.app.interaction.pointSlots", ...
    ["Axis", "Style", "Instruction", "ViewportPolicy"], varargin{:});
spec = labkit.app.internal.interaction.InteractionSpec("pointSlots",id,onChanged,options);
end
