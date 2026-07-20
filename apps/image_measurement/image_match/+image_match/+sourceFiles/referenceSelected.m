function applicationState = referenceSelected( ...
        applicationState, listSelection, callbackContext)
%REFERENCESELECTED Rebuild preview state for the selected reference image.
lastExport = applicationState.project.results.lastExport;
reference = applicationState.project.inputs.reference;
if ~isempty(lastExport) && isfield(lastExport, "referenceId")
    currentId = "";
    if ~isempty(reference)
        currentId = string(reference(1).id);
    end
    if string(lastExport.referenceId) ~= currentId
        applicationState = ...
            image_match.matchPipeline.invalidateResults(applicationState);
    end
end
applicationState.session.workflow.pendingDirty = false;
applicationState = ...
    image_match.matchPipeline.rebuildPreview(applicationState);
if isempty(listSelection.Indices) && isempty(reference)
    callbackContext.appendStatus("Reference image cleared.");
end
end
