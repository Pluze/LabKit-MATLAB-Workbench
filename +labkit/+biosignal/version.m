function info = version()
%VERSION Return the LabKit biosignal facade contract version.
%
% App-facing contract:
%   info = labkit.biosignal.version()
%
% Inputs:
%   None.
%
% Outputs:
%   info - plain struct describing the current labkit.biosignal contract, the
%       compatible contract ranges implemented by this code, contract status,
%       and a short maintainer note.

    info = labkit.contract.versionInfo("biosignal", "1.0.0", ">=1.0 <2", ...
        "stable", "Biosignal recording, filtering, event, segmentation, and ECG facade contract.");
end
