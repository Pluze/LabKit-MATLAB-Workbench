function opts = defaultPulseOptions()
%DEFAULTPULSEOPTIONS Return private defaults for chrono pulse detection.
%
% Output:
%   opts - struct with mode = "metadata_first".
%
% Notes:
%   Public callers configure pulse detection through labkit.dta.detectPulses.
%   Keep this helper private so the DTA facade owns the public option names.

    opts = struct();
    opts.mode = "metadata_first";
end
