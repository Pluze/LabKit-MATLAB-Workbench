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

    info = labkit.contract.versionInfo("ui", "3.2.6", ">=3.0 <4", ...
        "stable", "UI 3.x app/spec/view/tool/diag contract with compact single-file panels, toolPanel hosts, filePanel title context, debug trace, close guard, crash reports, output folder prompts, and default text fitting.");
end
