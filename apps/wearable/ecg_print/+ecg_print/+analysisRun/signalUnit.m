% Expected callers: ECG Print presentation builders. Input is a decoded
% signal struct. Output is the file-provided amplitude unit or the App's
% explicit uncalibrated-sample fallback. Side effects: none.
function unit = signalUnit(signal)
%SIGNALUNIT Return the reader-facing ECG amplitude unit.
unit = "ADC counts";
if ~isempty(signal) && isfield(signal, "unit") && ...
        strlength(strtrim(string(signal.unit))) > 0
    unit = strtrim(string(signal.unit));
end
end
