function spec = anchorPath(id, onChanged, varargin)
%ANCHORPATH Declare an editable open or closed path on one plot axis.
%
% Usage:
%   spec = labkit.app.interaction.anchorPath(id, onChanged, Name=Value)
%
% Description:
%   Creates the semantic declaration for a managed multi-anchor path editor;
%   the runtime owns native graphics, viewport preservation, and dispatch.
%   On an open path, a point placed beyond the visible start is prepended, a
%   point beyond the visible end is appended, and all other points are inserted
%   after the nearest visible curve segment. This ordering is independent of
%   the current axes zoom.
%
% Inputs:
%   id - Unique MATLAB identifier for this interaction.
%   onChanged - Callback state = callback(state,points,context).
%
% Options:
%   Axis - Axis ID within the owning plotArea. Default: "main".
%   Style - Scalar struct of anchor editor visual options. Default: struct().
%   Instruction - Scalar user guidance text. Default: "".
%   ViewportPolicy - "preserve" or "fit". Default: "preserve".
%
% Outputs:
%   spec - Immutable interaction declaration accepted by layout.plotArea.
%
% Errors:
%   Throws labkit:app:contract:* for invalid IDs, options, or callbacks.
%
% Typical Call:
%   spec = labkit.app.interaction.anchorPath( ...
%       "curve", @changeCurve, Style=struct("closed", false));
%
% See also labkit.app.layout.plotArea, labkit.app.view.Snapshot
spec = makeSpec("anchorPath", id, onChanged, ...
    ["Axis", "Style", "Instruction", "ViewportPolicy"], varargin{:});
end

function spec = makeSpec(kind, id, callback, names, varargin)
options = labkit.app.internal.OptionParser.parse( ...
    "labkit.app.interaction." + kind, names, varargin{:});
spec = labkit.app.internal.InteractionSpec(kind, id, callback, options);
end
