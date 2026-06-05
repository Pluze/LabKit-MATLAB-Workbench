function setTopBottomPlotSelections(topX, topY, bottomX, bottomY, topSelection, bottomSelection)
%SETTOPBOTTOMPLOTSELECTIONS Apply top/bottom plot dropdown selections.
%
% Inputs:
%   topX, topY, bottomX, bottomY - dropdown handles.
%   topSelection, bottomSelection - structs with x and y fields.
%
% Output:
%   Mutates dropdown Value properties in place.

    topX.Value = topSelection.x;
    topY.Value = topSelection.y;
    bottomX.Value = bottomSelection.x;
    bottomY.Value = bottomSelection.y;
end
