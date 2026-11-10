function model = morphologyModel(cache, requestedWindow)
%MORPHOLOGYMODEL Align window beats and the exact detrended samples used for SNR.
model = struct('window',1,'windowCount',1, ...
    'windowChoices',ecg_print.analysisRun.templateWindowChoices(cache.ecgNext), ...
    'time',[],'template',[],'beats',[],'beatNumbers',[], ...
    'unit',"ADC counts",'noiseBeats',struct([]),'templates',struct([]));
if isempty(cache.ecgNext), return; end
r = cache.ecgNext;
if isempty(r.windows), return; end
model.unit = ecg_print.analysisRun.signalUnit(cache.signal);
model.windowCount = numel(r.windows);
model.window = min(model.windowCount,max(1,round(requestedWindow)));
curves = repmat(struct('window',0,'time',[],'values',[]),numel(r.windows),1);
curveCount = 0;
for k=1:numel(r.windows)
    extraction = r.windows(k).extraction;
    if isempty(extraction), continue; end
    curveCount = curveCount+1;
    curves(curveCount) = struct('window',k, ...
        'time',extraction.alignment.time,'values',r.windows(k).template);
end
model.templates = curves(1:curveCount);
w = r.windows(model.window);
if isempty(w.extraction), return; end
e = w.extraction; a = e.alignment;
model.time = a.time;
model.template = w.template;
valid = any(isfinite(a.alignedBeats),2) & isfinite(a.timeShiftSamples(:));
model.beats = a.alignedBeats(valid,:);
globalBeats = find(r.rPeaks>=w.startIndex & r.rPeaks<=w.endIndex);
model.beatNumbers = globalBeats(valid);
noiseBeats = repmat(struct('beat',0,'time',[],'values',[],'sourceWindow',0),nnz(valid),1);
count = 0;
for j=find(valid)'
    beat=globalBeats(j);
    if r.perBeat.Status(beat)~="complete",continue;end
    mask = r.beatIndex(:)==beat;
    values = r.statisticsNoise.detrended(mask);
    if isempty(values)||any(~isfinite(values)),continue;end
    count = count+1;
    rTime = (r.rPeaks(beat)-1)/r.fs;
    % Reuse SNR's exact winning-window samples, even when an overlapping
    % template window is selected. Only horizontal display alignment changes.
    time = r.time(mask);
    noiseBeats(count) = struct('beat',beat, ...
        'time',time(:)-rTime+a.timeShiftSamples(j)/r.fs, ...
        'values',values(:),'sourceWindow',r.perBeat.Window(beat));
end
model.noiseBeats = noiseBeats(1:count);
end
