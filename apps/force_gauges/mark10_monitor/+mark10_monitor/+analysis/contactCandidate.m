function contact = contactCandidate(time, force)
%CONTACTCANDIDATE Suggest a sustained force-rise onset from an unloaded start.
contact = NaN;
valid = isfinite(time) & isfinite(force);
t = time(valid); f = force(valid);
t = t(:); f = f(:);
baselineDuration_s = 0.5;
minimumBaselineSamples = 6;
if numel(t)<=minimumBaselineSamples || any(diff(t)<=0), return; end
maximumGap_s = max(0.2,3*median(diff(t)));
baseline = t<t(1)+baselineDuration_s;
if nnz(baseline)<minimumBaselineSamples || all(baseline) || ...
        any(diff(t(baseline))>maximumGap_s), return; end
unloaded = f(baseline);
centre = median(unloaded);
noise = 1.4826*median(abs(unloaded-centre));
% Several observed gauge counts and a sustained departure from baseline
% suppress momentary excursions and isolated force quantization changes.
rise = max(3*mark10_monitor.analysis.observedIncrement(f), 6*noise);
persistence_s = 0.15;
continuous = diff(t)<=maximumGap_s;
above = centre-f >= rise & ~baseline;
starts = t(above & [true; ~above(1:end-1) | ~continuous]);
ends = t(above & [~above(2:end) | ~continuous; true]);
event = find(ends-starts>=persistence_s,1);
if ~isempty(event), contact=starts(event); end
end
