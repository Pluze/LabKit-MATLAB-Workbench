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
    labkit.ui.view.draw(ax, 'reset', titleText, resetScaleAndTicks);
end
