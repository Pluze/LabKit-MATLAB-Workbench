function ax = axes(parent, row, titleText, xLabelText, yLabelText)
%CREATEAXES Create an axes and apply its initial layout and labels.
%
% Inputs:
%   parent - parent grid.
%   row - logical parent row, mapped through layoutRow.
%   titleText, xLabelText, yLabelText - initial axes labels.
%
% Output:
%   ax - UI axes with standard popout context action enabled.

    ax = uiaxes(parent);
    ax.Layout.Row = layoutRow(parent, row);
    title(ax, titleText);
    xlabel(ax, xLabelText);
    ylabel(ax, yLabelText);
    enablePopout(ax);
end
