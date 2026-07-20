function applicationState = next(applicationState, callbackContext)
%NEXT Select and decode the following FLIR source.
sources = applicationState.project.inputs.sources;
if isempty(sources)
    return
end
index = min(numel(sources), ...
    applicationState.session.selection.currentIndex + 1);
selection = labkit.app.event.ListSelection( ...
    Ids=string(sources(index).id), Indices=index);
applicationState = flir_thermal.thermalSources.selectCurrent( ...
    applicationState, selection, callbackContext);
end
