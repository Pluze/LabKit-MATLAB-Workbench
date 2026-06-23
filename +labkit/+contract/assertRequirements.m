function assertRequirements(appName, req, versions)
%ASSERTREQUIREMENTS Require app facade contracts to match current LabKit.
%
% App-facing contract:
%   labkit.contract.assertRequirements(appName, req)
%   labkit.contract.assertRequirements(appName, req, versions)
%
% Inputs:
%   appName - app entry-point name used for the error identifier.
%   req - struct returned by labkit.contract.requirements.
%   versions - optional facade version struct array for tests or diagnostics.
%
% Outputs:
%   None. Throws <appName>:IncompatibleLabKit when a requirement fails.

    if nargin < 3
        report = labkit.contract.checkRequirements(req);
    else
        report = labkit.contract.checkRequirements(req, versions);
    end

    if report.ok
        return;
    end

    appName = char(string(appName));
    errorId = sprintf('%s:IncompatibleLabKit', appName);
    error(errorId, ...
        'LabKit facade requirements are not compatible:%s%s', ...
        newline, char(report.message));
end
