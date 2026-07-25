% Private DTA helper. Expected caller: labkit.dta facade and internal parser,
% session, pulse, or item pipeline. Inputs and outputs use internal structs,
% tables, file paths, or numeric vectors. Side effects: file discovery/parser reads
% only where named; assumes app-specific workflow decisions stay outside +labkit.
function [pulse, msg] = detectPulseCore(t, Im, meta, opts)
%DETECTPULSECORE Internal chrono pulse detector for the DTA facade.
%
% Called by:
%   labkit.dta.detectPulses and chrono item construction.
%
% Inputs:
%   t - time vector in seconds.
%   Im - measured current vector in ampere, same length as t.
%   meta - parsed chrono metadata struct with optional steps field.
%   opts - string mode or struct with mode. Accepted private modes are
%          "metadata_first", "metadata_only", and "current_only"; public
%          display labels are normalized here.
%
% Output:
%   pulse - pulse struct from emptyPulse with ok/method/message and
%           compatibility plus normalized pulse windows.
%   msg - human-readable detection status.
%
% Notes:
%   The metadata-first path prefers ISTEP/TSTEP or VSTEP/TSTEP timing and
%   falls back to measured-current segmentation only when needed.

    if nargin < 4 || isempty(opts)
        opts = defaultPulseOptions();
    elseif ischar(opts) || isstring(opts)
        [mode, recognized] = normalizeMode(opts);
        if ~recognized
            [pulse, msg] = unsupportedMode(opts);
            return
        end
        opts = struct('mode', mode);
    elseif ~isfield(opts, 'mode')
        opts.mode = "metadata_first";
    else
        modeText = opts.mode;
        [opts.mode, recognized] = normalizeMode(modeText);
        if ~recognized
            [pulse, msg] = unsupportedMode(modeText);
            return
        end
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

function [mode, recognized] = normalizeMode(modeText)
    recognized = true;
    switch string(modeText)
        case {"metadata_first", "Metadata first, then auto"}
            mode = "metadata_first";
        case {"metadata_only", "Metadata only"}
            mode = "metadata_only";
        case {"current_only", "Auto from Im only"}
            mode = "current_only";
        otherwise
            mode = "";
            recognized = false;
    end
end

function [pulse, msg] = unsupportedMode(modeText)
pulse = emptyPulse();
msg = sprintf("Unsupported pulse detection mode: %s.", string(modeText));
pulse.message = msg;
end
