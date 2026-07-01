function info = version()
%VERSION Return the LabKit thermal facade contract version.
%
% App-facing contract:
%   info = labkit.thermal.version()
%
% Inputs:
%   None.
%
% Outputs:
%   info - plain struct describing the current labkit.thermal contract,
%       compatible contract range, stability, and maintainer note.

    info = labkit.contract.versionInfo("thermal", "1.0.0", ">=1.0 <2", ...
        "experimental", "GUI-free thermal image facade for FLIR radiometric JPEG reads, raw sensor matrices, temperature conversion, and display rendering.");
end
