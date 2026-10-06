function estimate = estimateInitialLength(time, force, travel, p, kind)
%ESTIMATEINITIALLENGTH Infer baseline and contact from a user-bracketed episode.
% The supplied time is a visual hint, never a constraint on inferred contact.
% Fit the unloaded baseline first; compare local loading windows independently.
time=double(time(:)); force=double(force(:)); travel=double(travel(:));
if numel(time)~=numel(force) || numel(time)~=numel(travel)
    error("mark10_monitor:analysis:MismatchedData","Data columns must match.");
end
if ~isscalar(string(kind)) || ~any(string(kind)==mark10_monitor.analysis.experimentTypes())
    error("mark10_monitor:analysis:InvalidExperimentType","Choose a supported test type.");
end
episode=mark10_monitor.analysis.contactEpisode(time,travel,p.contactTime_s,string(kind));
range=[episode(1) p.contactTime_s episode(2)];
keep=isfinite(time)&isfinite(force)&isfinite(travel)&time>=range(1)&time<=range(3);
source=find(keep); t=time(keep); f=force(keep); x=travel(keep); excludedCount=0;
if p.excludeGlitches
    excluded=mark10_monitor.analysis.detectGlitches(f,x);
    excludedCount=nnz(excluded); t(excluded)=[];f(excluded)=[];x(excluded)=[];source(excluded)=[];
end
% Each side needs enough observations to distinguish baseline drift from load.
minimumSideSamples=6;
if numel(t)<2*minimumSideSamples+4 || any(diff(t)<=0)
    error("mark10_monitor:analysis:InsufficientContactFit", ...
        "Include sufficient ordered samples around contact.");
end
[f0,x0]=mark10_monitor.analysis.appliedZeroLevels(p); f=f-f0; x=x-x0;
polarity=1;
if kind=="Compression" || (kind=="Cyclic" && x(end)<x(1)),polarity=-1;end
travelSpan=polarity*(x(end)-x(1));
if travelSpan<=0
    error("mark10_monitor:analysis:InvalidContactFit","Reference travel must move in the loading direction.");
end
u=polarity*(x-x(1))/travelSpan;
% Reject a different loading/unloading episode, tolerating three travel ticks.
travelTicks=abs(diff(u));travelTicks=travelTicks(travelTicks>0);
reversalTolerance=max(3*median(travelTicks),64*eps);
if max(cummax(u)-u)>reversalTolerance
    error("mark10_monitor:analysis:InvalidContactFit", ...
        "The reference includes a travel reversal. Bracket one contact event.");
end
% A recording gap must not masquerade as an observed contact transition.
maximumGap_s=max(0.2,3*median(diff(t)));
if any(diff(t)>maximumGap_s)
    error("mark10_monitor:analysis:InvalidContactFit","Reference interval crosses an acquisition gap.");
end
y=polarity*f;
% The first half-second must be unloaded. This seed does not depend on the
% requested end time or approximate contact hint. Eight samples support drift.
seedDuration_s=0.5; minimumSeedSamples=8;
seedEnd=max(minimumSeedSamples,find(t<=t(1)+seedDuration_s,1,'last'));
seedEnd=min(seedEnd,numel(t)-minimumSideSamples);
ts=t-t(1);seed=(1:seedEnd).';
noiseFloor=64*eps(max(1,max(abs(y(seed)))));
noise=max(1.4826*median(abs(diff(y(seed))-median(diff(y(seed)))))/sqrt(2),noiseFloor);
[baseBeta,~]=robustFit([ones(size(seed)),ts(seed)],y(seed),noise);
base=[ones(size(t)),ts]*baseBeta;
% A persistent departure from the seed baseline locates initial loading.
% Six noise scales and 0.15 s suppress isolated spikes without a force-unit knob.
runSamples=max(4,ceil(.15/median(diff(t))));
above=y-base>6*noise;
ends=find(conv(double(above),ones(runSamples,1),'valid')==runSamples,1);
if isempty(ends) || ends<=seedEnd
    error("mark10_monitor:analysis:ContactNotResolved", ...
        "No unloaded-to-loaded transition is resolved. Start earlier with unloaded data and include initial loading.");
end
baselineIndices=(1:ends-1).';
[baseBeta,~]=robustFit([ones(size(baselineIndices)),ts(baselineIndices)],y(baselineIndices),noise);
base=[ones(size(t)),ts]*baseBeta;corrected=y-base;
noise=max(1.4826*median(abs(corrected(baselineIndices)-median(corrected(baselineIndices)))),noiseFloor);
% Compare 4%, 8%, 12% travel excursions relative to onset gap: initial
% deformation rather than a fraction of the full force peak. These are model
% sensitivity probes, not prescribed material modulus windows.
fractions=[.04 .08 .12]; onsetGap=x(ends);
if onsetGap<=0,error("mark10_monitor:analysis:InvalidContactFit","Initial loading gap is not positive; review fixture closure.");end
endIndices=zeros(size(fractions));
for k=1:numel(fractions)
    last=find(polarity*(x-x(ends))>=fractions(k)*onsetGap,1);
    if isempty(last),last=numel(t);end
    endIndices(k)=last;
end
endIndices=unique(endIndices);
fits=cell(size(endIndices));lengths=NaN(size(endIndices));
for k=1:numel(endIndices)
    last=endIndices(k);
    first=find(polarity*(x-x(ends))>=-.12*onsetGap,1);
    indices=(first:last).';
    if numel(unique(x(ends:last)))<4 || numel(indices)<16,continue;end
    % Limit numerical work only; diagnostic points and curve export stay native.
    pick=indices(unique(round(linspace(1,numel(indices),min(600,numel(indices))))));
    u=polarity*(x(pick)-x(first))/onsetGap;
    upper=polarity*(x(last)-x(first))/onsetGap;
    bounds=[0 upper];best=struct('score',Inf,'contact',NaN,'degree',1,'beta',[]);
    grid=linspace(bounds(1),bounds(2),81);
    for degree=1:2
        scores=arrayfun(@(c) modelScore(c,degree,u,corrected(pick),noise),grid);
        [~,j]=min(scores);
        contact=fminbnd(@(c) modelScore(c,degree,u,corrected(pick),noise), ...
            grid(max(1,j-1)),grid(min(numel(grid),j+1)),optimset('Display','off','TolX',1e-11));
        [score,beta]=modelScore(contact,degree,u,corrected(pick),noise);
        if score<best.score,best=struct('score',score,'contact',contact,'degree',degree,'beta',beta);end
    end
    if ~isfinite(best.score),continue;end
    best.indices=indices;best.origin=x(first);best.scale=onsetGap;
    best.boundary=best.contact<=bounds(1)+.01*diff(bounds) || best.contact>=bounds(2)-.01*diff(bounds);
    fits{k}=best;lengths(k)=x(first)+polarity*onsetGap*best.contact;
end
valid=find(isfinite(lengths)&lengths>0);
if isempty(valid)
    error("mark10_monitor:analysis:InsufficientContactFit", ...
        "Too little initial loading travel for contact fitting. Extend the end slightly; retain unloaded baseline.");
end
[~,middle]=min(abs(lengths(valid)-median(lengths(valid))));best=fits{valid(middle)};
h0=lengths(valid(middle));indices=best.indices;
h=max(polarity*(x-h0)/best.scale,0);loadFit=(h.^(1:best.degree))*best.beta;
loaded=indices(h(indices)>0);residual=corrected(loaded)-loadFit(loaded);
total=sum((corrected(loaded)-mean(corrected(loaded))).^2);r2=NaN;
if total>0,r2=1-sum(residual.^2)/total;end
[ux,ix]=unique(polarity*x,'sorted');contactTime=interp1(ux,t(ix),polarity*h0);
[~,nearest]=min(abs(t-contactTime));
modelGap=linspace(min(x(indices)),max(x(indices)),300).';
modelH=max(polarity*(modelGap-h0)/best.scale,0);modelForce=(modelH.^(1:best.degree))*best.beta;
spread=100*(max(lengths(valid))-min(lengths(valid)))/h0;
% A 2% spread is a review flag, not a physical accuracy/confidence guarantee.
windowStabilityReview_percent=2;
quality="Stable across local windows";
if numel(valid)<2,quality="Limited data: extend initial loading for a stability check";
elseif spread>windowStabilityReview_percent,quality="Sensitive to fit window: review or use measured length";end
if best.boundary,quality="Contact near search boundary: include more unloaded data";end
modelName="Linear initial loading";if best.degree==2,modelName="Curved initial loading";end
baselineAtContact=baseBeta(1)+baseBeta(2)*(contactTime-t(1));
estimate=struct("length_mm",h0,"time_s",contactTime,"sampleIndex",source(nearest), ...
    "anchorTime_s",range(2),"anchorGap_mm",interp1(t,x,range(2)), ...
    "referenceGap_mm",x,"referenceForce_N",corrected,"referenceTime_s",t, ...
    "observedForce_N",y,"baselineFit_N",base,"fullFit_N",base+loadFit, ...
    "modelGap_mm",modelGap,"modelForce_N",modelForce, ...
    "baselineForce_N",f0+polarity*baselineAtContact,"noise_N",noise, ...
    "modelName",modelName,"rSquared",r2,"count",numel(loaded), ...
    "baselineCount",numel(baselineIndices),"polarity",polarity, ...
    "referenceRange_s",range([1 3]),"excludedCount",excludedCount, ...
    "fitIndices",indices,"baselineIndices",baselineIndices,"quality",quality, ...
    "lengthRange_mm",[min(lengths(valid)) max(lengths(valid))],"spread_percent",spread);
end

function [score,beta]=modelScore(contact,degree,u,y,noise)
h=max(u-contact,0);design=h.^(1:degree);
if nnz(h>0)<6 || rank(design)<degree,score=Inf;beta=zeros(degree,1);return;end
[beta,loss]=robustFit(design,y,noise);
endSlope=beta(1);if degree==2,endSlope=endSlope+2*beta(2)*max(h);end
if beta(1)<-64*eps(max(1,norm(beta))) || endSlope<=0,score=Inf;return;end
score=numel(y)*log(max(1,loss))+(degree+1)*log(numel(y));
end

function [beta,loss]=robustFit(design,y,noise)
% Huber IRLS: fixed unloaded noise scale prevents large later loads dominating.
huberSigma=1.345;beta=design\y;
for iteration=1:20
    residual=(y-design*beta)/noise;weights=min(1,huberSigma./max(abs(residual),eps));
    next=(design.*sqrt(weights))\(y.*sqrt(weights));
    if norm(next-beta)<=1e-12*max(1,norm(beta)),beta=next;break;end
    beta=next;
end
r=abs((y-design*beta)/noise);
loss=mean(min(r,huberSigma).^2+2*huberSigma*max(r-huberSigma,0));
end
