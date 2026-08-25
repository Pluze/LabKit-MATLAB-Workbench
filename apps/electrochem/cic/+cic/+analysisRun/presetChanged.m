% App-owned implementation for cic.analysisRun.presetChanged within the cic product workflow.
function applicationState = presetChanged( ...
        applicationState, ~, ~)
%PRESETCHANGED Apply the selected literature window preset and recompute once.
choices = cic.analysisRun.analysisChoices();
preset = string(applicationState.project.parameters.preset);
if preset == choices.presets(1)
    applicationState.project.parameters.cathLimit = -0.6;
    applicationState.project.parameters.anodLimit = 0.8;
elseif preset == choices.presets(2)
    applicationState.project.parameters.cathLimit = -0.9;
    applicationState.project.parameters.anodLimit = 0.6;
end
applicationState = cic.analysisRun.settingsChanged( ...
    applicationState, [], []);
end
