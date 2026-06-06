% Private DTA helper. Expected caller: labkit.dta facade and internal parser,
% session, pulse, or item pipeline. Inputs and outputs use internal structs,
% tables, file paths, or numeric vectors. Side effects: file discovery/parser reads
% only where named; assumes app-specific workflow decisions stay outside +labkit.
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
