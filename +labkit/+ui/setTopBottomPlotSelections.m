function setTopBottomPlotSelections(topX, topY, bottomX, bottomY, topSelection, bottomSelection)
%SETTOPBOTTOMPLOTSELECTIONS Apply top/bottom plot dropdown selections.

    topX.Value = topSelection.x;
    topY.Value = topSelection.y;
    bottomX.Value = bottomSelection.x;
    bottomY.Value = bottomSelection.y;
end
