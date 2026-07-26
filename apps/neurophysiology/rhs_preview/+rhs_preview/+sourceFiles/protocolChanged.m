% App-owned implementation for rhs_preview.sourceFiles.protocolChanged within the rhs_preview product workflow.
function applicationState = protocolChanged( ...
        applicationState, selection, callbackContext)
%PROTOCOLCHANGED Persist the selected protocol and rebuild role rows.
arguments
    applicationState (1, 1) struct
    selection (1, 1) labkit.app.event.ListSelection
    callbackContext (1, 1) labkit.app.CallbackContext
end
if isempty(selection.Indices) || ...
        strlength(applicationState.session.cache.protocolPath) == 0
    applicationState.project.annotations.protocol = struct();
    applicationState.session.cache.protocol = struct();
else
    applicationState.project.annotations.protocol = ...
        applicationState.session.cache.protocol;
end
applicationState.project.annotations.previewChannelRows = table();
applicationState.session = rhs_preview.analysisRun.rebuildPreviewRows( ...
    applicationState.session, applicationState.project.parameters, table());
applicationState.project.annotations.previewChannelRows = ...
    applicationState.session.cache.previewChannelRows;
if applicationState.session.view.autoWindow
    applicationState.session = rhs_preview.analysisRun.applyAdaptiveWindow( ...
        applicationState.session, applicationState.project.parameters);
end
[applicationState.session, ok, message] = ...
    rhs_preview.analysisRun.readCurrentPreview( ...
        applicationState.session, applicationState.project.parameters, ...
        "Selected protocol", false);
applicationState.session.workflow.lastAction = "Selected protocol";
rhs_preview.analysisRun.logPreviewRead(callbackContext, ok, message, ...
    "rhs_preview.sourcefiles.protocolchanged.preview");
end
