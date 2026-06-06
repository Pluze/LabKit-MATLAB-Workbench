% Expected caller: ecg_print.ui.runApp and direct unit tests. Inputs are the
% measurement per-segment table and smoothing width in beats. Output preserves
% existing columns and adds smoothed SignalP2P, NoiseRMS, and SNRdB columns.
% Side effects: none.

function T = analysisTable(perSegment, smoothBeats)
%ANALYSISTABLE Build the ECG Print segment SNR export/display table.

    T = perSegment;
    smoothBeats = max(1, round(smoothBeats));
    T.SignalP2P_smooth = movingMedian(T.SignalP2P, smoothBeats);
    T.NoiseRMS_smooth = movingMedian(T.NoiseRMS, smoothBeats);
    T.SNRdB_smooth = movingMedian(T.SNRdB, smoothBeats);
end

function y = movingMedian(x, width)
    x = double(x(:));
    width = max(1, round(width));
    y = nan(size(x));
    for i = 1:numel(x)
        i1 = max(1, i - floor((width - 1) / 2));
        i2 = min(numel(x), i + ceil((width - 1) / 2));
        y(i) = median(x(i1:i2), 'omitnan');
    end
end
