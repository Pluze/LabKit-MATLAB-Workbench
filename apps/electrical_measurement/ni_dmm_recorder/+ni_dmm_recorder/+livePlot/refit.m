function applicationState = refit(applicationState, ~)
%REFIT Request one renderer-owned fit of the current measurement domain.
applicationState.session.cache.plotRevision = ...
    applicationState.session.cache.plotRevision + 1;
end
