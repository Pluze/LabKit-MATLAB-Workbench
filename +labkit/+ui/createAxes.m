function ax = createAxes(parent, row, titleText, xLabelText, yLabelText)
%CREATEAXES Create an axes and apply its initial layout and labels.

    ax = uiaxes(parent);
    ax.Layout.Row = labkit.ui.layoutRow(parent, row);
    title(ax, titleText);
    xlabel(ax, xLabelText);
    ylabel(ax, yLabelText);
end
