function events = refineRPeaks(events, raw, minimumRR)
%REFINERPEAKS Move positive R anchors to maxima in prepared raw ECG.
% Search only +/-20 ms, matching the facade's final localization radius but
% using the actual prepared raw trace rather than the 5-20 Hz detector input.
% Keep beat identity, ordering and minimum spacing; do not add/remove beats.
original=events.index(:);refined=original;
searchSeconds=.020;
radius=max(1,round(searchSeconds*raw.fs));
for k=1:numel(original)
    center=original(k);
    first=max(1,center-radius);last=min(numel(raw.values),center+radius);
    if k>1,first=max(first,floor((original(k-1)+center)/2)+1);end
    if k<numel(original),last=min(last,ceil((center+original(k+1))/2)-1);end
    indices=first:last;scores=raw.values(indices);
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
