function clearAxes(ui, id, axisId)
%CLEARAXES Clear a UI 4.0 previewArea axes.
%
% App-facing contract:
%   labkit.ui.view.clearAxes(ui, id, axisId)
%
% Inputs:
%   ui - UI registry returned by labkit.ui.app.create.
%   id - semantic id for a previewArea.
%   axisId - optional named axes id.
%
% Output:
%   None.

    if nargin < 3
        axisId = "";
    end
    control = resolveControl(ui, id);
    ax = controlAxes(control, axisId);
    if ~isempty(ax.Children)
        delete(ax.Children);
    end
    clearImageViewState(ax);
    hold(ax, 'off');
    ax.XLimMode = 'auto';
    ax.YLimMode = 'auto';
end

function clearImageViewState(ax)
    key = 'labkitImageViewBounds';
    if isappdata(ax, key)
        rmappdata(ax, key);
    end
end
