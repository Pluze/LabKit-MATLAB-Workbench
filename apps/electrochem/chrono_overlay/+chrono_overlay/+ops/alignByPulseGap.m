% Expected caller: chrono overlay app runner and unit tests. Inputs are one
% chrono item struct with time/current/voltage and pulse fields. Outputs return
% the aligned item and status message. No file or UI side effects.
function [item, msg] = alignByPulseGap(item)
    [item, msg] = chrono_overlay.core.dispatch("alignByPulseGap", item);
end
