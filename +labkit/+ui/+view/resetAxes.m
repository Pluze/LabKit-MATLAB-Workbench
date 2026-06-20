function resetAxes(ui, id, titleText, resetScaleAndTicks, axisId)
%RESETAXES Reset a UI 2.0 previewArea axes.
%
% App-facing contract:
%   labkit.ui.view.resetAxes(ui, id, titleText, resetScaleAndTicks, axisId)
%
% Inputs:
%   ui - UI registry returned by labkit.ui.app.create.
%   id - semantic id for a previewArea.
%   titleText - optional axes title.
%   resetScaleAndTicks - optional logical, default false.
%   axisId - optional named axes id.
%
% Output:
%   None.

    if nargin < 3
        titleText = '';
    end
    if nargin < 4
        resetScaleAndTicks = false;
    end
    if nargin < 5
        axisId = "";
    end
    control = resolveControl(ui, id);
    ax = controlAxes(control, axisId);
    cla(ax, 'reset');
    clearImageViewState(ax);
    ax.NextPlot = 'replace';
    ax.XLimMode = 'auto';
    ax.YLimMode = 'auto';
    if resetScaleAndTicks
        ax.XScale = 'linear';
        ax.YScale = 'linear';
        ax.XTickMode = 'auto';
        ax.YTickMode = 'auto';
    end
    title(ax, titleText);
    xlabel(ax, '');
    ylabel(ax, '');
    grid(ax, 'off');
    box(ax, 'on');
    enablePopout(ax);
end

function clearImageViewState(ax)
    key = 'labkitImageViewBounds';
    if isappdata(ax, key)
        rmappdata(ax, key);
    end
end
