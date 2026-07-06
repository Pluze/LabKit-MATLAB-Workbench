function clearPreview(ui, id, axisId)
%CLEARPREVIEW Clear a UI 5 previewArea axes.
%
% App-facing contract:
%   labkit.ui.plot.clearPreview(ui, id, axisId)
%
% Inputs:
%   ui - UI registry returned by labkit.ui.runtime.create.
%   id - semantic id for a previewArea.
%   axisId - optional named axes id.
%
% Output:
%   None.

    if nargin < 3
        axisId = "";
    end
    control = resolvePlotControl(ui, id);
    ax = controlAxes(control, axisId);
    children = allchild(ax);
    for k = 1:numel(children)
        if isgraphics(children(k)) && isvalid(children(k))
            delete(children(k));
        end
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
