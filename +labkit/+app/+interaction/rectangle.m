function spec = rectangle(id, onChanged, varargin)
%RECTANGLE Declare an editable rectangular plot region.
%
% Usage:
%   spec = labkit.app.interaction.rectangle(id,onChanged,Name=Value)
%
% Description:
%   Creates the semantic declaration for a persistent editable rectangle,
%   including an optional background-point callback on the same axis.
%
% Inputs:
%   id - Unique MATLAB identifier.
%   onChanged - Callback state = callback(state,position,context).
%
% Options:
%   Axis - Axis ID. Default: "main".
%   Style - Scalar visual-option struct. Default: struct().
%   Instruction - Scalar guidance text. Default: "".
%   ViewportPolicy - "preserve" or "fit". Default: "preserve".
%   OnBackgroundPressed - Optional callback
%       state = callback(state,point,context). Default: [].
%
% Outputs:
%   spec - Immutable interaction declaration.
%
% Errors:
%   Throws labkit:app:contract:* for invalid values.
%
% Typical Call:
%   spec = labkit.app.interaction.rectangle("crop",@moveCrop);
%
% See also labkit.app.layout.plotArea
options = labkit.app.internal.OptionParser.parse( ...
    "labkit.app.interaction.rectangle", ...
    ["Axis", "Style", "Instruction", "ViewportPolicy", ...
     "OnBackgroundPressed"], varargin{:});
spec = labkit.app.internal.InteractionSpec("rectangle",id,onChanged,options);
end
