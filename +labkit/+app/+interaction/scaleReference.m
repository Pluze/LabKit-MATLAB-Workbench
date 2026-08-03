function spec = scaleReference(id, onChanged, varargin)
%SCALEREFERENCE Declare an editable two-point scale reference.
%
% Usage:
%   spec = labkit.app.interaction.scaleReference(id,onChanged,Name=Value)
%
% Description:
%   Creates the semantic declaration for an editable two-endpoint physical
%   scale reference while the runtime owns its native editor lifecycle.
%
% Inputs:
%   id - Unique MATLAB identifier.
%   onChanged - Callback state = callback(state,endpoints,context).
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
%   spec = labkit.app.interaction.scaleReference("scale",@changeScale);
%
% See also labkit.app.layout.plotArea
options = labkit.app.internal.contract.OptionParser.parse( ...
    "labkit.app.interaction.scaleReference", ...
    ["Axis", "Style", "Instruction", "ViewportPolicy"], varargin{:});
spec = labkit.app.internal.interaction.InteractionSpec( ...
    "scaleReference",id,onChanged,options);
end
