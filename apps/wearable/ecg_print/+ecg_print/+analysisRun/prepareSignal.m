function [raw, bandpassed, preparation, detector] = prepareSignal(signal, timeRange)
%PREPARESIGNAL Crop and prepare one ECG channel on a 1000 Hz sample grid.
%   [raw, bandpassed, preparation] = ecg_print.analysisRun.prepareSignal(signal,
%   timeRange) accepts a LabKit signal with finite values, uniform time in
%   seconds, fs >=100 Hz, and [start end] ROI (end<=start means whole record).
%   Above 1000 Hz, a reflection-padded App FIR with 450 Hz cutoff precedes
%   linear interpolation. Below 1000 Hz, interpolation adds no bandwidth.
%   bandpassed uses the fixed 0.5-40 Hz Butterworth preparation; both signals
%   have fs=1000 and zero-based ROI time. metadata.sourceStartSeconds retains
%   source coordinates. preparation records the source rate and adapter.
%   ROI samples alone enter resampling and filtering. A 15-second even
%   reflection from within the ROI precedes morphology filtering to settle
%   the slow high-pass poles without importing excluded artifacts. detector
%   is the 5-20 Hz FIR branch on the same selected raw grid.
%   Invalid input raises ecg_print:InvalidPreparation; crop errors propagate.
%   No files, graphics, or optional Toolboxes are used.
%   See also ecg_print.analysisRun.ecgNextBandpass.
if ~isscalar(signal.fs) || ~isfinite(signal.fs) || signal.fs < 100 || ...
        ~isnumeric(signal.values) || ~isvector(signal.values) || ...
        ~isreal(signal.values) || any(~isfinite(signal.values)) || ...
        numel(signal.time) ~= numel(signal.values) || ...
        any(~isfinite(signal.time)) || numel(signal.values) < 32
    error('ecg_print:InvalidPreparation', 'Use a finite uniform ECG sampled at 100 Hz or above.');
end
sourceTime = double(signal.time(:));
sourceFs = signal.fs;
if any(abs(diff(sourceTime)-1/signal.fs) > max(1e-8,1e-4/signal.fs))
    error('ecg_print:InvalidPreparation', 'Use a uniform time grid without acquisition gaps.');
end
if timeRange(2) > timeRange(1)
    selected = sourceTime >= timeRange(1) & sourceTime <= timeRange(2);
    if nnz(selected) < 32
        error('ecg_print:InvalidPreparation','Select at least 32 samples within the recording.');
    end
    signal.values = signal.values(selected);
    sourceTime = sourceTime(selected);
end
signal.fs = sourceFs;
preparation = struct('sourceFs', sourceFs, 'fs', 1000, ...
    'sourceTimeRangeSeconds', [sourceTime(1) sourceTime(end)], ...
    'resampling', "none", 'antialiasCutoffHz', NaN);
if sourceFs > 1000
    antialiasCutoffHz = 450;
    design = ecg_print.analysisRun.firDesign(sourceFs, [0 antialiasCutoffHz]);
    signal = ecg_print.analysisRun.applyFir(signal, design);
    preparation.antialiasCutoffHz = antialiasCutoffHz;
    preparation.resampling = "450 Hz antialias FIR then linear interpolation";
elseif sourceFs < 1000
    preparation.resampling = "linear interpolation; source-limited bandwidth";
end
raw = signal;
time = (0:numel(signal.values)-1)'/sourceFs;
raw.time = (0:floor((numel(signal.values)-1)*1000/sourceFs))'/1000;
if sourceFs == 1000
    raw.values = double(signal.values(:));
else
    raw.values = interp1(time, double(signal.values(:)), raw.time, 'linear');
end
raw.fs = 1000;
% The slowest SOS pole has radius about .99905 at 1000 Hz. Fifteen
% seconds of context reduces its homogeneous response below 1e-6. Even
% reflection avoids imposing a DC step proportional to an endpoint R peak.
contextSeconds = 15;
pad = min(round(contextSeconds*raw.fs),numel(raw.values)-1);
x = raw.values;
extended = [x(pad+1:-1:2);x;x(end-1:-1:end-pad)];
y = ecg_print.analysisRun.ecgNextBandpass(extended);
bandpassed = raw;
bandpassed.values = y(pad+(1:numel(x)));
detector = ecg_print.analysisRun.applyFir(raw, ...
    ecg_print.analysisRun.firDesign(raw.fs,[5 20]));
raw.metadata.sourceStartSeconds = sourceTime(1);
bandpassed.metadata.sourceStartSeconds = sourceTime(1);
detector.metadata.sourceStartSeconds = sourceTime(1);
preparation.filterContext = "selected ROI only; even reflection from inside ROI";
preparation.reflectionSeconds = pad/raw.fs;

end
