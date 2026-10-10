function result = ecgNextAnalysis(raw, bandpassed, events, progress)
%ECGNEXTANALYSIS Extract ECGNExT noise and assign estimates to every R beat.
%   result = ecg_print.analysisRun.ecgNextAnalysis(raw, bandpassed, events)
%   accepts equal-length prepared LabKit signals at 1000 Hz and accurate R
%   indices in events.index. At least 30000 samples are required. For longer
%   recordings, 60000-sample windows overlap by 30000 samples; a final window
%   ends at the last sample. Each extraction uses the unchanged FDA core.
%   An optional progress(completed,total) callback receives window progress.
%
%   Per-beat noise samples inherit nearest-R midpoint intervals through the
%   reference QRS removal/crossfade. For each beat, the complete candidate
%   closest to a window center is selected. A boundary candidate may remain
%   for display but has NaN RMS/ratio. No sample is reused across beat rows.
%   NoiseRMS uses each beat's samples after NST one-second chunk centering.
%   QRSNoiseDb=20*log10(QRSPeakToPeak/(sqrt(8)*NoiseRMS)).
%   QRSPeakToPeak uses filtered R +/-50 ms. An incomplete final noise
%   chunk is unavailable. nstNoise retains centering and chunk provenance.
%   These statistics and beat attribution are App additions, not FDA outputs.
%   result.noise/time retain exact selected reference samples and coordinates.
%   windows retains each complete extraction and its input interval.
%   ok/statusCode/status distinguish completion from insufficient duration or
%   unusable peaks. Source amplitude units are unchanged. No IO or graphics.
%   Invalid prepared signals raise ecg_print:InvalidECGNextInput. Unexpected
%   errors propagate; unsupported reference geometry is recorded per window.
%   See also ecg_print.analysisRun.ecgNextExtract.
if nargin < 4, progress = []; end
if raw.fs ~= 1000 || bandpassed.fs ~= 1000 || ...
        numel(raw.values) ~= numel(bandpassed.values) || ...
        any(~isfinite(raw.values)) || any(~isfinite(bandpassed.values))
    error('ecg_print:InvalidECGNextInput', 'Prepare equal finite signals at 1000 Hz.');
end
r = double(events.index(:));
if any(~isfinite(r)) || any(r ~= fix(r)) || any(diff(r) <= 0) || ...
        any(r < 1 | r > numel(raw.values))
    error('ecg_print:InvalidECGNextInput', 'Use strictly increasing R indices.');
end
n = numel(raw.values); count = numel(r);
result = struct('ok', false, 'statusCode', "short-record", ...
    'status', "Select at least 30 seconds of ECG.", ...
    'perBeat', table(), 'noise', [], 'time', [], 'beatIndex', [], ...
    'synthetic', NaN(n,1), 'windows', struct([]), ...
    'raw', raw.values, 'bandpassed', bandpassed.values, 'rPeaks', r, ...
    'fs', 1000, 'noiseRMS', NaN, 'qrsP2P', NaN, 'nstNoise', struct([]), ...
    'referenceCommit', "972c66cb274319acf705776d723b8e52372e22f0", ...
    'blankSeconds', .040, 'blendSeconds', .060);
qrs = ecg_print.analysisRun.qrsAmplitude(bandpassed.values, r, 1000);
qrsValues = NaN(count,1);
completeQrs = r-50 >= 1 & r+50 <= n;
qrsValues(completeQrs) = qrs.perBeat;
result.perBeat = table((1:count)', (r-1)/1000, zeros(count,1), qrsValues, ...
    NaN(count,1), NaN(count,1), zeros(count,1), repmat("boundary",count,1), ...
    'VariableNames', {'Beat','RTime','Window','QRSPeakToPeak', ...
    'NoiseRMS','QRSNoiseDb','NoiseSamples','Status'});
if n < 30000, return; end
if count < 4
    result.statusCode = "insufficient-peaks";
    result.status = "Review peak detection: at least four R peaks are required.";
    return;
end
windowLength = min(n, 60000);
starts = unique([1:30000:n-windowLength+1, n-windowLength+1]);
chosen = cell(count,1); bestDistance = Inf(count,1); bestComplete = false(count,1);
windows = repmat(struct('startIndex',0,'endIndex',0,'template',[], ...
    'status',"insufficient-peaks",'extraction',[]),numel(starts),1);
for w = 1:numel(starts)
    first = starts(w); last = first+windowLength-1;
    globalBeats = find(r>=first & r<=last);
    windows(w).startIndex = first; windows(w).endIndex = last;
    if numel(globalBeats) >= 4
        localR = r(globalBeats)-first+1;
        try
            extracted = ecg_print.analysisRun.ecgNextExtract( ...
                raw.values(first:last), bandpassed.values(first:last), localR,1000);
            windows(w).template = extracted.template;
            windows(w).extraction = extracted;
            windows(w).status = "complete";
            for j = 1:numel(globalBeats)
                b = globalBeats(j);
                mask = extracted.beatIndex == j;
                isComplete = extracted.beatComplete(j);
                distance = abs(r(b)-(first+last)/2);
                if any(mask) && ((isComplete && ~bestComplete(b)) || ...
                        (isComplete == bestComplete(b) && distance < bestDistance(b)))
                    chosen{b} = struct('noise',extracted.noise(mask)', ...
                        'time',extracted.time(mask)' +(first-1)/1000);
                    bestComplete(b) = isComplete; bestDistance(b) = distance;
                    result.perBeat.Window(b) = w;
                    left = 1; right = n;
                    if b>1, left = ceil((r(b-1)+r(b))/2); end
                    if b<count, right = ceil((r(b)+r(b+1))/2)-1; end
                    indices = max(first,left):min(last,right);
                    result.synthetic(indices) = extracted.synthetic(indices-first+1);
                end
            end
        catch cause
            if ~startsWith(string(cause.identifier), "ecg_print:")
                rethrow(cause);
            end
            windows(w).status = "peak-geometry";
        end
    end
    if ~isempty(progress), progress(w,numel(starts)); end
end
noise = cell(count,1); time = noise; identities = noise;
for b = 1:count
    if isempty(chosen{b}), continue; end
    c = chosen{b}; noise{b}=c.noise; time{b}=c.time;
    identities{b} = repmat(b,numel(c.noise),1);
    result.perBeat.NoiseSamples(b) = numel(c.noise);
    if bestComplete(b) && isfinite(qrsValues(b))
        result.perBeat.Status(b) = "complete";
    end
end
result.noise = vertcat(noise{:}); result.time = vertcat(time{:});
result.beatIndex = vertcat(identities{:});
result.windows = windows;
% Preserve FDA output; only the separate statistics branch removes chunk DC.
result.nstNoise = ecg_print.analysisRun.nstNoise(result.noise,1000);
for b=find(result.perBeat.Status=="complete")'
    values=result.nstNoise.centered(result.beatIndex==b);
    if isempty(values)||any(~isfinite(values))
        result.perBeat.Status(b)="boundary";
        continue;
    end
    rmsNoise=sqrt(mean(values.^2));
    result.perBeat.NoiseRMS(b)=rmsNoise;
    result.perBeat.QRSNoiseDb(b)=20*log10(qrsValues(b)/(sqrt(8)*rmsNoise));
end
valid = result.perBeat.Status == "complete";
result.ok = any(valid);
if result.ok
    samples = ismember(result.beatIndex, find(valid));
    result.noiseRMS = sqrt(mean(result.nstNoise.centered(samples).^2));
    amplitudes = sort(qrsValues(valid)); trim = floor(.05*numel(amplitudes));
    result.qrsP2P = mean(amplitudes(trim+1:end-trim));
    result.statusCode = "complete";
    result.status = sprintf('ECGNExT: %d of %d beats measured in %d windows.', ...
        nnz(valid),count,numel(starts));
else
    result.statusCode = "peak-geometry";
    result.status = "Review the detected R peaks and select a stable ECG interval.";
end
end
