function spec = pairedAnchors(id, onChanged, varargin)
%PAIREDANCHORS Declare matching editable points across plot axes.
%
% Usage:
%   spec = labkit.app.interaction.pairedAnchors(id,onChanged,Name=Value)
%
% Description:
%   Creates the semantic declaration for corresponding editable points across
%   two or more axes while the runtime owns their native editors.
%
% Inputs:
%   id - Unique MATLAB identifier.
%   onChanged - Callback state = callback(state,pointSets,context).
%
% Options:
%   Axes - Two or more axis IDs within the owning plotArea. Required.
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
%   spec = labkit.app.interaction.pairedAnchors("matches",@changeMatches);
%
% See also labkit.app.layout.plotArea
options = labkit.app.internal.OptionParser.parse( ...
    "labkit.app.interaction.pairedAnchors", ...
    ["Axes", "Style", "Instruction", "ViewportPolicy"], varargin{:});
if ~isfield(options, "Axes")
    error("labkit:app:contract:UnknownArgument", ...
        "labkit.app.interaction.pairedAnchors requires Axes.");
end
spec = labkit.app.internal.InteractionSpec( ...
    "pairedAnchors", id, onChanged, options);
end
