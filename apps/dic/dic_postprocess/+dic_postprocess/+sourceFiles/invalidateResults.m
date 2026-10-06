function applicationState = invalidateResults( ...
        applicationState, ~, callbackContext)
%INVALIDATERESULTS Clear outputs after any source collection changes.
applicationState.project.results.summaryTable = table();
applicationState.session.cache.strain = struct();
applicationState.session.cache.overlayExx = [];
applicationState.session.cache.overlayEyy = [];
callbackContext.log("info", "dic_postprocess.sourcefiles.invalidateresults.status", "Updated DIC postprocess inputs.");
end
