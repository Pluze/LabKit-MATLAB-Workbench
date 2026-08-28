function spec = pointSlots(id, onChanged, varargin)
%POINTSLOTS Declare a fixed set of editable labeled point positions.
%
% Usage:
%   spec = labkit.app.interaction.pointSlots(id,onChanged,Name=Value)
%
% Description:
%   Creates the semantic declaration for a fixed, labeled set of editable
%   points. Pressing a point drags it, pressing a selected group drags the
%   group, and dragging from empty plot space selects the enclosed points.
%
% Inputs:
%   id - Unique MATLAB identifier.
%   onChanged - Callback state = callback(state,value,context).
%
% Options:
%   Axis - Axis ID. Default: "main".
%   Style - Scalar visual-option struct. Default: struct().
%   Instruction - Scalar guidance text. Default: "".
%   OnSelectionChanged - Optional callback receiving the selected point
%       indices after a point click or empty-space marquee gesture.
%       Default: [].
%   OnBackgroundPressed - Optional callback receiving the clicked plot point
%       when empty space is clicked without a marquee drag. Default: [].
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
    ["Axis", "Style", "Instruction", "OnSelectionChanged", ...
     "OnBackgroundPressed"], varargin{:});
spec = labkit.app.internal.interaction.InteractionSpec("pointSlots",id,onChanged,options);
end
