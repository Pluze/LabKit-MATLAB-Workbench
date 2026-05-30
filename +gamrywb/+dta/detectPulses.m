function [pulse, message] = detectPulses(t, Im, meta, mode)
%DETECTPULSES Detect chrono pulse windows through the DTA facade.

    if nargin < 3
        meta = struct();
    end
    if nargin < 4
        mode = "Metadata first, then auto";
    end

    [pulse, message] = gamrywb.analysis.detectPulses(t, Im, meta, mode);
end
