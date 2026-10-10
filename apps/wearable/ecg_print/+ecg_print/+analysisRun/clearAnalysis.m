function applicationState = clearAnalysis(applicationState)
%CLEARANALYSIS Invalidate derived products while retaining decoded source.
cache = applicationState.session.cache;
cache.workingSignal = cache.signal; cache.filteredSignal = [];
cache.peakDetectionSignal = []; cache.events = []; cache.ecgNext = [];
cache.plotViewRevision = cache.plotViewRevision+1;
applicationState.session.cache = cache;
applicationState.project.results = struct();
end
