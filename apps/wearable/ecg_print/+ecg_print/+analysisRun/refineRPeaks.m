function events = refineRPeaks(events, raw, detector, minimumRR)
%REFINERPEAKS Move detector anchors to same-polarity extrema in prepared raw ECG.
% Search only +/-20 ms, matching the facade's final localization radius but
% using the actual prepared raw trace rather than the 5-20 Hz detector input.
% Keep beat identity, ordering and minimum spacing; do not add/remove beats.
original=events.index(:);refined=original;
searchSeconds=.020;baselineSeconds=.100;
radius=max(1,round(searchSeconds*raw.fs));
baselineRadius=max(radius,round(baselineSeconds*raw.fs));
for k=1:numel(original)
    center=original(k);
    context=max(1,center-baselineRadius):min(numel(detector.values),center+baselineRadius);
    direction=sign(detector.values(center)-median(detector.values(context)));
    if direction==0,continue;end
    first=max(1,center-radius);last=min(numel(raw.values),center+radius);
    if k>1,first=max(first,floor((original(k-1)+center)/2)+1);end
    if k<numel(original),last=min(last,ceil((center+original(k+1))/2)-1);end
    indices=first:last;scores=direction*raw.values(indices);
    candidates=indices(scores==max(scores));
    [~,nearest]=min(abs(candidates-center));refined(k)=candidates(nearest);
end
% Revert conflicting moves until all accepted anchors retain minimum spacing.
minimumSamples=round(minimumRR*raw.fs);
while true
    conflicts=find(diff(refined)<minimumSamples & diff(refined)<diff(original));
    if isempty(conflicts),break;end
    revert=unique([conflicts;conflicts+1]);refined(revert)=original(revert);
end
events.index=refined;
events.time=raw.time(refined);events.amplitude=raw.values(refined);
events.metadata.rawLocalization=struct('detectorIndex',original, ...
    'shiftSamples',refined-original,'searchSeconds',searchSeconds, ...
    'trace',"prepared raw ECG");
end
