function [pulse, message] = detectPulses(t, Im, meta, mode)
%DETECTPULSES Detect chrono pulse windows through the DTA facade.
%
% Usage:
%   [pulse, message] = labkit.dta.detectPulses(t, Im, meta);
%   [pulse, message] = labkit.dta.detectPulses(t, Im, meta, "Auto from Im only");
%
% Inputs:
%   t - time vector in seconds.
%   Im - current vector in amps, same length as t.
%   meta - optional chrono metadata struct containing ISTEP/TSTEP fields.
%   mode - optional char/string or struct with mode field.
%
% Mode values:
%   "Metadata first, then auto" / "metadata_first" (default)
%   "Metadata only" / "metadata_only"
%   "Auto from Im only" / "current_only"
%
% Output:
%   pulse - pulse struct with flat compatibility fields and nested cath,
%           anod, and gap fields.
%   message - status text describing detection path.

    if nargin < 3
        meta = struct();
    end
    if nargin < 4
        mode = "Metadata first, then auto";
    end

    [pulse, message] = detectPulseCore(t, Im, meta, mode);
end
