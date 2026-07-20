function applicationState = editRange( ...
        applicationState, range, ~)
%EDITRANGE Commit one dragged ROI inside the current preview samples.
range = double(range(:)).';
preview = applicationState.session.cache.preview;
if numel(range) ~= 2 || ~all(isfinite(range)) || ...
        ~isstruct(preview) || ~isfield(preview, "timeSec") || ...
        isempty(preview.timeSec)
    return;
end
applicationState.session.view.roiSec = ...
    rhs_preview.analysisRun.clampRoi(range, preview.timeSec);
roi = applicationState.session.view.roiSec;
applicationState.session.workflow.statusMessage = string(sprintf( ...
    "ROI %.6g to %.6g s.", roi(1), roi(2)));
applicationState.session.workflow.lastAction = "Updated preview ROI";
end
