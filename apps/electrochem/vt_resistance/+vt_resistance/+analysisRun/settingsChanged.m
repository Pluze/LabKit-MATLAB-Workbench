function applicationState = settingsChanged( ...
        applicationState, ~, ~)
%SETTINGSCHANGED Recompute loaded analysis after one committed parameter edit.
items = applicationState.session.cache.items;
if ~isempty(items)
    options = vt_resistance.analysisRun.optionsFromParameters( ...
        applicationState.project.parameters);
    applicationState.session.cache.items = ...
        vt_resistance.analysisRun.recomputeItems(items, options);
end

end
