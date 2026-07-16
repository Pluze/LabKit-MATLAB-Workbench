% Private UI runtime helper. Resolves framework-owned preview axes by
% semantic preview and optional axis ids.
function ax = resolvePreviewAxes(ui, id, axisId)
%
% Internal contract:
%   ax = resolvePreviewAxes(ui, id, axisId)
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
    if nargin < 3
        axisId = "";
    end
    control = resolvePlotControl(ui, id);
    ax = controlAxes(control, axisId);
end
