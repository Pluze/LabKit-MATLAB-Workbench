function model = debugModel(cache, overlay)
%DEBUGMODEL Five full-interval stages with explicit measurement sources.
empty=trace([],[],"", "",strings(0,1));
model=struct('raw',empty,'template',empty,'residual',empty,'noise',empty,'metricNoise',empty,'beatNoise',empty,'beatPeak',empty,'beatSnr',empty, ...
    'description',"Analyze a recording to inspect its signal chain.", ...
    'overlay',logical(overlay),'limits',[0 1],'rTimes',[]);
if isempty(cache.ecgNext),return;end
r=cache.ecgNext;model.rTimes=(r.rPeaks-1)/r.fs;t=(0:numel(r.raw)-1)'/r.fs;
if numel(t)>1,model.limits=[t(1) t(end)];end
model.raw=trace(t,r.raw,"1  Input ECG - "+string(cache.signal.displayName),r.unit,"Input ECG");
model.template=trace(t,[r.synthetic r.bandpassed],"2  SNR signal: filtered ECG (blue, QRS p-p) + template (orange-red dashed)", ...
    r.unit,["Template","Filtered ECG: p-p"]);
model.residual=trace(t,r.raw-r.synthetic,"3  Residual: input - template | shaded: removed QRS",r.unit,"Residual x - s");
model.noise=trace(r.time,r.noise, ...
    "4  ECGNExT output: QRS removed + crossfaded",r.unit,"ECGNExT noise (unchanged)");
detrended=NaN(size(r.noise));
if ~isempty(r.statisticsNoise),detrended=r.statisticsNoise.detrended;end
% Independent beat fits need not join continuously. Gaps prevent plotting a
% connecting edge between distinct beat statistics as a noise transient.
indices=zeros(0,1);
if ~isempty(r.noise)
    indices=(1:numel(r.noise))'+cumsum([0;diff(r.beatIndex(:))~=0]);
end
plotTime=NaN(numel(r.noise)+nnz(diff(r.beatIndex(:))),1);plotValues=plotTime;
plotTime(indices)=r.time;plotValues(indices)=detrended;
model.metricNoise=trace(plotTime,plotValues, ...
    "5  SNR noise: per-beat linear detrend (gaps between beats)",r.unit,"Detrended noise used for RMS");
model.beatNoise=trace(r.perBeat.RTime,r.perBeat.NoiseRMS, ...
    "6  Detrended noise RMS per beat",r.unit,"Noise RMS");
model.beatPeak=trace(r.perBeat.RTime,r.perBeat.QRSPeakToPeak, ...
    "7  QRS peak-to-peak per beat",r.unit,"QRS p-p");
model.beatSnr=trace(r.perBeat.RTime,r.perBeat.QRSNoiseDb, ...
    "8  SNR per beat","dB","SNR");
model.description=strjoin([ ...
    "SNR = 20 log10(QRS p-p / (sqrt(8) RMS)). Signal: plot 2; noise: plot 5."; ...
    "Noise RMS: remove each beat's fitted constant + linear drift on its own samples. Custom estimate; not NST calibration."],newline);
end
function s=trace(t,y,titleText,unit,names)
s=struct('time',t,'values',y,'title',titleText,'unit',unit,'names',names);
end
