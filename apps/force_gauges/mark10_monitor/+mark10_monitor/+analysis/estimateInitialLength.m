function estimate = estimateInitialLength(time, force, travel, p, kind)
%ESTIMATEINITIALLENGTH Extrapolate a local loading ramp to reviewed zero force.
% The reference interval is independent of the modulus analysis interval.
% Threshold locates an episode; it is never a silent fallback for failed fits.
time=double(time(:)); force=double(force(:)); travel=double(travel(:));
if numel(time)~=numel(force) || numel(time)~=numel(travel)
    error("mark10_monitor:analysis:MismatchedData","Data columns must match.");
end
if p.referenceStart_s>=p.referenceEnd_s || ...
        any(~isfinite([p.referenceStart_s p.referenceEnd_s]))
    error("mark10_monitor:analysis:InvalidTimeRange","Contact reference start must precede end.");
end
if any(~isfinite([p.contactMin_N p.contactMax_N])) || ...
        p.contactMin_N<=0 || p.contactMin_N>=p.contactMax_N
    error("mark10_monitor:analysis:InvalidContactRange","Use positive increasing low-force bounds.");
end
keep=isfinite(time)&isfinite(force)&isfinite(travel)&time>=p.referenceStart_s&time<=p.referenceEnd_s;
source=find(keep); t=time(keep); f=force(keep); x=travel(keep);
excludedCount=0;
if p.excludeGlitches
    excluded=mark10_monitor.analysis.detectGlitches(f,x);
    excludedCount=nnz(excluded); t(excluded)=[];f(excluded)=[];x(excluded)=[];source(excluded)=[];
end
q=p; q.excludeGlitches=false;
onset=mark10_monitor.analysis.estimateOnset(t,f,x,q,kind);
[f0,x0]=mark10_monitor.analysis.appliedZeroLevels(p);
f=f-f0; x=x-x0;
polarity=1;
if kind=="Compression" || (kind=="Cyclic" && f(onset.sampleIndex)<0), polarity=-1; end
load=polarity*f;
k=onset.sampleIndex;
% Retain the nearest low-force ramp, not earlier approach or reversal points.
lookback_s=35;
first=find(t>=t(k)-lookback_s,1);
below=find(load(first:k)<p.contactMin_N,1,'last');
if ~isempty(below), first=first+below; end
% Do not include an earlier unloading ramp or bridge missing acquisition.
minimumGapBreak_s=0.2; cadenceGapFactor=3;
maximumGap_s=max(minimumGapBreak_s,cadenceGapFactor*median(diff(t)));
for j=k:-1:first+1
    if t(j)-t(j-1)>maximumGap_s || polarity*(x(j)-x(j-1))<0
        first=j; break;
    end
end
last=k;
while last<numel(t) && load(last)<=p.contactMax_N
    if t(last+1)-t(last)>maximumGap_s, break; end
    if polarity*(x(last+1)-x(last))<0, break; end
    last=last+1;
end
indices=(first:last).';
indices=indices(load(indices)>=p.contactMin_N & load(indices)<=p.contactMax_N);
if numel(indices)<4 || numel(unique(x(indices)))<2
    error("mark10_monitor:analysis:InsufficientContactFit", ...
        "Not enough local low-force points. Adjust reference/force bounds or enter measured length.");
end
xx=x(indices); yy=load(indices); xc=xx-mean(xx); yc=yy-mean(yy);
slope=sum(xc.*yc)/sum(xc.^2); intercept=mean(yy)-slope*mean(xx);
h0=-intercept/slope;
if ~isfinite(h0) || h0<=0 || polarity*slope<=0
    error("mark10_monitor:analysis:InvalidContactFit", ...
        "Contact fit has invalid height or loading direction. Review the interval or enter measured length.");
end
total=sum(yc.^2); r2=NaN;
if total>0, r2=1-sum((yy-(slope*xx+intercept)).^2)/total; end
estimate=struct("length_mm",h0,"thresholdLength_mm",onset.length_mm, ...
    "time_s",onset.time_s,"sampleIndex",source(k),"threshold_N",onset.threshold_N, ...
    "fitGap_mm",xx,"fitForce_N",yy,"slope",slope,"intercept",intercept, ...
    "rSquared",r2,"count",numel(indices),"polarity",polarity, ...
    "referenceRange_s",[p.referenceStart_s p.referenceEnd_s],"excludedCount",excludedCount);
end
