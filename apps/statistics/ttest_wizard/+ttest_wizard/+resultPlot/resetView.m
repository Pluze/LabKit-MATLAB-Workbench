% App callback; requests one renderer-owned best-fit viewport refresh.
function applicationState = resetView(applicationState, ~)
%RESETVIEW Increment the transient plot viewport revision.
%
% Inputs:
%   applicationState - Current T-Test Wizard project and session state.
%
% Outputs:
%   applicationState - State with one incremented transient view revision.
%
% Side effects: none. Results, plot settings, and project data are unchanged.

    revision = applicationState.session.cache.plotViewRevision;
    applicationState.session.cache.plotViewRevision = revision + 1;
end
