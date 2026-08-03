% App-owned implementation for dic_preprocess.analysisRun.rebuildCache within the dic_preprocess product workflow.
function applicationState = rebuildCache(applicationState)
%REBUILDCACHE Replay durable edit steps into transient working images.
cache = applicationState.session.cache;
plotViewRevision = cache.plotViewRevision;
applicationState.session.cache = ...
    dic_preprocess.analysisRun.replayEditSteps( ...
        cache.referenceImage, cache.movingImage, ...
        applicationState.project.annotations.editSteps);
applicationState.session.cache.plotViewRevision = plotViewRevision;
end
