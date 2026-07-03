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

    info = labkit.contract.versionInfo("ui", "3.4.5", ">=3.0 <4", ...
        "stable", "UI 3.x app/spec/view/tool/diag contract with declarative app definitions, framework-owned runtime dispatch, debounced parameter callbacks, spinner-backed panners, reusable image preview redraws, compact file panels, toolPanel file entry helpers, filePanel title context, preview-area row/column sizing, visible-window early paint, startup readiness state, lazy preview scroll-interaction setup, debug trace, debug artifact sample/output folders, hidden-test-safe alerts, close guard, crash reports, output folder prompts, and default text fitting.");
end
