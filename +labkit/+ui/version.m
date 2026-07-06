function info = version()
%VERSION Return the LabKit UI facade contract version.
%
% App-facing contract:
%   info = labkit.ui.version()
%
% Inputs:
%   None.
%
% Outputs:
%   info - plain struct describing the current labkit.ui contract, the
%       compatible contract ranges implemented by this code, contract status,
%       and a short maintainer note.

    info = labkit.contract.versionInfo("ui", "5.0.0", ">=5 <6", ...
        "stable", "UI 5 runtime/layout/control/plot/interaction/debug contract with declarative app definitions, data-only workbench layouts, semantic control updates, framework-owned plot clearing and limit fitting, plot coordinate conversion helpers, reusable image preview rendering, interaction tools, debug artifacts, hidden-test-safe alerts, close guards, state snapshot save/load, and app version title formatting.");
end
