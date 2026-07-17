function assertRequirements(appName, req, versions)
%ASSERTREQUIREMENTS Throw an error when LabKit API requirements are not met.
%
% Usage:
%   labkit.contract.assertRequirements(appName, req)
%   labkit.contract.assertRequirements(appName, req, versions)
%
% Description:
%   Calls checkRequirements and returns normally when every requirement is
%   compatible. On failure, combines the individual report messages into one
%   error. Use checkRequirements instead when incompatibility should be shown
%   without throwing.
%
% Inputs:
%   appName - Text scalar used as the error-identifier prefix. It should be a
%       valid MATLAB identifier, for example "labkit_Example_app".
%   req - Scalar structure returned by labkit.contract.requirements.
%   versions - Optional version structure array accepted by checkRequirements.
%
% Outputs:
%   None - Returns no value.
%
% Errors:
%   Throws <appName>:IncompatibleLabKit when compatibility checks fail. Input
%   and range validation errors from checkRequirements are passed through.
%
% Example:
%   req = labkit.contract.requirements("ui", ">=7 <8");
%   labkit.contract.assertRequirements("labkit_Example_app", req)
%
% See also labkit.contract.checkRequirements,
%   labkit.contract.requirements

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
