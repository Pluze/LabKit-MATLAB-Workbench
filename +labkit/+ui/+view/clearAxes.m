function clearAxes(ui, id, axisId)
%CLEARAXES Clear a UI 2.0 previewArea axes.
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
    labkit.ui.view.draw(ax, 'clear');
end
