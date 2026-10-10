function model = recordingModel(cache,parameters)
%RECORDINGMODEL Bounded raw-file preview with pending ROI in source seconds.
model=struct('time',[],'values',[],'range',[parameters.roiStart parameters.roiEnd], ...
    'unit',"ADC counts");
if isempty(cache.signal),return;end
s=cache.signal;model.unit=ecg_print.analysisRun.signalUnit(s);
% Min/max bins preserve short artifacts when reviewing a long file.
limit=6000;n=numel(s.values);
if n<=limit,ids=(1:n)';
else
    edges=round(linspace(1,n+1,limit/2+1));ids=zeros(limit,1);
    for k=1:numel(edges)-1
        range=edges(k):edges(k+1)-1;
        [~,lo]=min(s.values(range));[~,hi]=max(s.values(range));
        ids(2*k-1:2*k)=sort(range([lo hi]));
    end
end
model.time=s.time(ids);model.values=s.values(ids);
end
