function info = version()
%VERSION Return the LabKit DTA facade contract version.
%
% App-facing contract:
%   info = labkit.dta.version()
%
% Inputs:
%   None.
%
% Outputs:
%   info - plain struct describing the current labkit.dta contract, the
%       compatible contract ranges implemented by this code, contract status,
%       and a short maintainer note.

    info = labkit.contract.versionInfo("dta", "1.0.0", ">=1.0 <2", ...
        "stable", "DTA parser, session, item, pulse, and curve facade contract.");
end
