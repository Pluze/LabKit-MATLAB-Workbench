function ax = getAxes(ui, id, axisId)
%GETAXES Return a previewArea axes handle by semantic ids.
%
% App-facing contract:
%   ax = labkit.ui.plot.getAxes(ui, id)
%   ax = labkit.ui.plot.getAxes(ui, id, axisId)
%
% Inputs:
%   ui - UI registry returned by labkit.ui.runtime.create or app runtime.
%   id - semantic id for a previewArea.
%   axisId - optional named axes id. When omitted, the preview area's primary
%       axes is returned.
%
% Outputs:
%   ax - MATLAB axes or uiaxes handle owned by the previewArea.
%
% Example:
%   ax = labkit.ui.plot.getAxes(ui, "plotAxes", "top");
%   plot(ax, t, y);

    if nargin < 3
        axisId = "";
    end
    control = resolvePlotControl(ui, id);
    ax = controlAxes(control, axisId);
end
