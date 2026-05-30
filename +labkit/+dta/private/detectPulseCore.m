function [pulse, msg] = detectPulseCore(t, Im, meta, opts)
%DETECTPULSECORE Internal chrono pulse detector for the DTA facade.

    if nargin < 4 || isempty(opts)
        opts = defaultPulseOptions();
    elseif ischar(opts) || isstring(opts)
        opts = struct('mode', normalizeMode(opts));
    elseif ~isfield(opts, 'mode')
        opts.mode = "metadata_first";
    else
        opts.mode = normalizeMode(opts.mode);
    end

    pulse = emptyPulse();
    msg = 'Pulse detection failed.';

    switch string(opts.mode)
        case "metadata_only"
            [pulse, ~, msg] = pulsesFromMetadata(meta, t);
        case "current_only"
            [pulse, ~, msg] = pulsesFromCurrent(t, Im);
        otherwise
            [pulse, okM, msgM] = pulsesFromMetadata(meta, t);
            if okM
                msg = msgM;
                pulse.message = msg;
                return;
            end

            [pulse, okA, msgA] = pulsesFromCurrent(t, Im);
            if okA
                msg = sprintf('%s | fallback success: %s', msgM, msgA);
            else
                msg = sprintf('%s | %s', msgM, msgA);
            end
    end

    pulse.message = msg;
end

function mode = normalizeMode(modeText)
    switch string(modeText)
        case {"metadata_first", "Metadata first, then auto"}
            mode = "metadata_first";
        case {"metadata_only", "Metadata only"}
            mode = "metadata_only";
        case {"current_only", "Auto from Im only"}
            mode = "current_only";
        otherwise
            mode = "metadata_first";
    end
end
