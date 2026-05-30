function swapTopBottomPlotSelections(topX, topY, bottomX, bottomY)
%SWAPTOPBOTTOMPLOTSELECTIONS Swap top and bottom plot dropdown values.

    topXValue = topX.Value;
    topYValue = topY.Value;
    bottomXValue = bottomX.Value;
    bottomYValue = bottomY.Value;

    topX.Value = bottomXValue;
    topY.Value = bottomYValue;
    bottomX.Value = topXValue;
    bottomY.Value = topYValue;
end
