% Expected caller: ecg_print.userInterface.updateWorkbenchFromState and direct unit tests. Inputs are the
% current working/filtered signal structs and optional event struct. Output is a
% GUI-free plot request struct; no UI handles are read or mutated.

function request = waveformPlotRequest(workingSignal, filteredSignal, events)
%WAVEFORMPLOTREQUEST Prepare ECG Print waveform plot data.

    request = struct( ...
        'ok', false, ...
        'x', [], ...
        'y', [], ...
        'peakX', [], ...
        'peakY', [], ...
        'title', 'Waveform + Peaks', ...
        'xLabel', 'Time (s)', ...
        'yLabel', 'Amplitude', ...
        'lineColor', [0.15 0.38 0.72], ...
        'peakColor', [0.85 0.25 0.15]);

    if isempty(workingSignal)
        return;
    end

    sig = workingSignal;
    if ~isempty(filteredSignal)
        sig = filteredSignal;
    end

    request.ok = true;
    request.x = sig.time;
    request.y = sig.values;
    request.yLabel = char(sig.name);

    if ~isempty(events) && isfield(events, 'index') && ~isempty(events.index)
        idx = events.index;
        request.peakX = sig.time(idx);
        request.peakY = sig.values(idx);
    end
end
