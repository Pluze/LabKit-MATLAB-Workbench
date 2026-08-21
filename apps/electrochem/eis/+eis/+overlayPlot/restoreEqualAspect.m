% App callback; requests equal X/Y data units for the current plot.
function applicationState = restoreEqualAspect(applicationState, ~)
%RESTOREEQUALASPECT Replace the current viewport with equal X/Y data units.
%
% Inputs:
%   applicationState - Current EIS project and transient session state.
%
% Outputs:
%   applicationState - State whose next render uses equal axis aspect and a
%       new viewport revision.
%
% Side effects: none. The current runtime data, loaded sources, and plot options
% are unchanged.

    applicationState.session.cache.plotViewAction = "equal";
    applicationState.session.cache.plotViewRevision = ...
        applicationState.session.cache.plotViewRevision + 1;
end
