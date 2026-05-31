function swapTopBottomPlotSelections(topX, topY, bottomX, bottomY)
%SWAPTOPBOTTOMPLOTSELECTIONS Swap top and bottom plot dropdown values.
%
% Inputs:
%   topX, topY, bottomX, bottomY - dropdown handles.
%
% Output:
%   Mutates dropdown Value properties in place.

    topXValue = topX.Value;
    topYValue = topY.Value;
    bottomXValue = bottomX.Value;
    bottomYValue = bottomY.Value;

    topX.Value = bottomXValue;
    topY.Value = bottomYValue;
    bottomX.Value = topXValue;
    bottomY.Value = topYValue;
end
