% App callback; requests independent best-fit X/Y limits for the current data.
function applicationState = fitLimits(applicationState, ~)
%FITLIMITS Replace the current viewport with independent data-fitted limits.
%
% Inputs:
%   applicationState - Current EIS project and transient session state.
%
% Outputs:
%   applicationState - State whose next render uses normal axis aspect and a
%       new viewport revision.
%
% Side effects: none. The durable project, loaded sources, and plot options
% are unchanged.

    applicationState.session.cache.plotViewAction = "fit";
    applicationState.session.cache.plotViewRevision = ...
        applicationState.session.cache.plotViewRevision + 1;
end
