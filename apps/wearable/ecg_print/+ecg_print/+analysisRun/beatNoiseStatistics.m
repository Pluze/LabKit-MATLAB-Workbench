function result = beatNoiseStatistics(noise,time,beatIndex,beatComplete)
%BEATNOISESTATISTICS Remove a fitted line independently within each complete beat.
%   result = ecg_print.analysisRun.beatNoiseStatistics(noise,time,beatIndex,beatComplete)
%   accepts equal-length finite real noise/time vectors, nondecreasing time,
%   integer beat identities in 1:numel(beatComplete), and a logical complete-
%   beat vector. time is the ECGNExT crossfaded reference in seconds; it is
%   not replaced by compressed output sample indices. Noise units are kept.
%   Each eligible beat is fitted by least squares to an intercept plus time.
%   detrended contains the residual; trend contains the removed line. Both
%   remain NaN for incomplete beats, fewer than three samples or zero time
%   spread. No output samples are added, interpolated or shared across beats.
%   fits records sample counts, time centers, removed means and slopes in
%   input-amplitude units per second. This App statistic reduces constant and
%   locally linear drift; it has no fixed frequency cutoff and is neither
%   total noise power nor the WFDB NST calibration method. No IO or graphics.
%   Invalid inputs raise ecg_print:InvalidBeatNoiseInput.
if ~isnumeric(noise)||~isreal(noise)||(~isempty(noise)&&~isvector(noise))|| ...
        ~isnumeric(time)||~isreal(time)||(~isempty(time)&&~isvector(time))|| ...
        ~isnumeric(beatIndex)||~isreal(beatIndex)|| ...
        (~isempty(beatIndex)&&~isvector(beatIndex))|| ...
        numel(noise)~=numel(time)||numel(noise)~=numel(beatIndex)|| ...
        any(~isfinite(noise(:)))||any(~isfinite(time(:)))||any(diff(time(:))<0)|| ...
        ~islogical(beatComplete)||(~isempty(beatComplete)&&~isvector(beatComplete))|| ...
        any(~isfinite(beatIndex(:)))||any(beatIndex(:)~=fix(beatIndex(:)))|| ...
        any(beatIndex(:)<1|beatIndex(:)>numel(beatComplete))
    error('ecg_print:InvalidBeatNoiseInput','Use finite noise/time and valid beat identities and completeness.');
end
noise=double(noise(:));time=double(time(:));beatIndex=beatIndex(:);
count=numel(beatComplete);detrended=NaN(size(noise));trend=detrended;
NoiseSamples=zeros(count,1);TimeCenter=NaN(count,1);RemovedMean=TimeCenter;RemovedSlope=TimeCenter;
for b=1:count
    ids=find(beatIndex==b);NoiseSamples(b)=numel(ids);
    if ~beatComplete(b)||numel(ids)<3,continue;end
    t=time(ids);v=noise(ids);center=mean(t);u=t-center;
    spread=sum(u.^2);
    if spread==0,continue;end
    offset=mean(v);slope=sum(u.*(v-offset))/spread;
    residual=(v-offset)-slope*u;
    detrended(ids)=residual;trend(ids)=offset+slope*u;
    TimeCenter(b)=center;RemovedMean(b)=offset;RemovedSlope(b)=slope;
end
fits=table((1:count)',NoiseSamples,TimeCenter,RemovedMean,RemovedSlope, ...
    'VariableNames',{'Beat','NoiseSamples','TimeCenter','RemovedMean','RemovedSlope'});
result=struct('detrended',detrended,'trend',trend,'fits',fits, ...
    'method',"per-beat least-squares linear detrend", ...
    'timeBasis',"ECGNExT crossfaded reference time (seconds)");
end
