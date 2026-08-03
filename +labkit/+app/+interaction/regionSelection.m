function spec = regionSelection(id, onSelected, varargin)
%REGIONSELECTION Declare a transient click-or-drag region gesture.
%
% Usage:
%   spec = labkit.app.interaction.regionSelection(id,onSelected,Name=Value)
%
% Description:
%   Creates the semantic declaration for a transient click-or-drag selection
%   whose result is delivered without exposing native interaction objects.
%
% Inputs:
%   id - Unique MATLAB identifier.
%   onSelected - Callback state = callback(state,position,context).
%
% Options:
%   Axis - Axis ID. Default: "main".
%   Style - Scalar visual-option struct. Default: struct().
%   Instruction - Scalar guidance text. Default: "".
%   ViewportPolicy - "preserve" or "fit". Default: "preserve".
%   OnBackgroundPressed - Optional point callback. Default: [].
%
% Outputs:
%   spec - Immutable interaction declaration.
%
% Errors:
%   Throws labkit:app:contract:* for invalid values.
%
% Typical Call:
%   spec = labkit.app.interaction.regionSelection( ...
%       "temperatureRegion",@measureRegion, ...
%       OnBackgroundPressed=@measurePoint);
%
% See also labkit.app.layout.plotArea
options = labkit.app.internal.contract.OptionParser.parse( ...
    "labkit.app.interaction.regionSelection", ...
    ["Axis", "Style", "Instruction", "ViewportPolicy", ...
     "OnBackgroundPressed"], varargin{:});
spec = labkit.app.internal.interaction.InteractionSpec( ...
    "regionSelection",id,onSelected,options);
end
