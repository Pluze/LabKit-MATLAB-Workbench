function applicationState = selectIndex(applicationState, index, callbackContext)
%SELECTINDEX Select and load one source image by collection index.
sources = applicationState.project.inputs.sources;
if isempty(sources)
    return
end
index = min(max(1, round(double(index))), numel(sources));
selection = labkit.app.event.ListSelection( ...
    Ids=string(sources(index).id), Indices=index);
applicationState.session.selection.sourceImages = selection;
applicationState = roi_analyzer.sourceImages.select( ...
    applicationState, selection, callbackContext);
end
