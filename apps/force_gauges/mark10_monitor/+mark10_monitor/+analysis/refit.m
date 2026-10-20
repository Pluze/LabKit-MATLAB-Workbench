function applicationState = refit(applicationState, ~)
%REFIT Restore the stress-strain viewport without recalculating the fit.
applicationState.session.analysis.viewRevision = ...
    applicationState.session.analysis.viewRevision + 1;
end
