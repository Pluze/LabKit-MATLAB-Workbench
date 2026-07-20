% App-owned implementation for flir_thermal.thermalSources.previous within the flir_thermal product workflow.
function applicationState = previous( ...
        applicationState, callbackContext)
%PREVIOUS Select and decode the preceding FLIR source.
index = max(1, applicationState.session.selection.currentIndex - 1);
applicationState = selectIndex( ...
    applicationState, index, callbackContext);
end

function applicationState = selectIndex( ...
        applicationState, index, callbackContext)
sources = applicationState.project.inputs.sources;
if isempty(sources)
    return
end
selection = labkit.app.event.ListSelection( ...
    Ids=string(sources(index).id), Indices=index);
applicationState = flir_thermal.thermalSources.selectCurrent( ...
    applicationState, selection, callbackContext);
end
