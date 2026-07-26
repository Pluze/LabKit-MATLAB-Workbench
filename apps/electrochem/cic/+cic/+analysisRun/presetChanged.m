% App-owned implementation for cic.analysisRun.presetChanged within the cic product workflow.
function applicationState = presetChanged( ...
        applicationState, ~, callbackContext)
%PRESETCHANGED Apply the selected literature window preset and recompute.
choices = cic.analysisRun.analysisChoices();
preset = string(applicationState.project.parameters.preset);
if preset == choices.presets(1)
    applicationState.project.parameters.cathLimit = -0.6;
    applicationState.project.parameters.anodLimit = 0.8;
elseif preset == choices.presets(2)
    applicationState.project.parameters.cathLimit = -0.9;
    applicationState.project.parameters.anodLimit = 0.6;
end
items = applicationState.session.cache.items;
if ~isempty(items)
    applicationState.session.cache.items = ...
        cic.analysisRun.recomputeLoaded( ...
            items, applicationState.project.parameters);
    callbackContext.log("info", "cic.analysisrun.presetchanged.status", sprintf( ...
        "Reanalyzed %d loaded CIC file(s) for the selected preset.", ...
        numel(items)));
end
applicationState.project.results.lastExport = [];
end
