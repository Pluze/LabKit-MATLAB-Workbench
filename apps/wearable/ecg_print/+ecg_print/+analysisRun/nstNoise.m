function result = nstNoise(noise,fs)
%NSTNOISE Center successive one-second extracted-noise chunks for statistics.
%   result = ecg_print.analysisRun.nstNoise(noise,fs) accepts a finite real
%   noise vector and positive integer sample rate. centered contains samples
%   minus their own fs-sample chunk mean; an incomplete trailing chunk is NaN.
%   blocks records FirstSample, LastSample, RemovedMean and NoiseRMS for each
%   complete chunk. Empty input returns empty output. Input samples are never
%   changed. Invalid inputs raise ecg_print:InvalidNSTInput.
%   This is the one-second centering/RMS stage of WFDB NST (floating arithmetic,
%   without integer ADC truncation). Every chunk is processed for per-beat
%   trends. NST's 300-second cap and 5%-per-tail aggregation are not per-beat
%   operations and are not applied here. The caller assigns centered samples
%   to beats and computes beat RMS; that attribution is an App extension.
%   One second means fs output samples after ECGNExT QRS deletion, not a
%   one-second interval on its nonuniform plotting-time coordinates. No IO.
%   Reference: https://physionet.org/physiotools/wag/nst-1.htm
if ~isnumeric(noise)||~isreal(noise)|| ...
        (~isempty(noise)&&~isvector(noise))||any(~isfinite(noise(:)))|| ...
        ~isnumeric(fs)||~isreal(fs)||~isscalar(fs)||~isfinite(fs)||fs<1||fs~=fix(fs)
    error('ecg_print:InvalidNSTInput','Use finite noise and a positive integer sample rate.');
end
noise=noise(:);count=floor(numel(noise)/fs);
v=reshape(noise(1:count*fs),fs,count);
means=mean(v,1)';centered=v-means';
rmsValues=sqrt(mean(centered.^2,1))';
first=(0:count-1)'*fs+1;last=first+fs-1;
blocks=table(first,last,means,rmsValues, ...
    'VariableNames',{'FirstSample','LastSample','RemovedMean','NoiseRMS'});
values=NaN(size(noise));values(1:count*fs)=centered(:);
result=struct('centered',values,'blocks',blocks,'sampleRate',fs, ...
    'reference',"https://physionet.org/physiotools/wag/nst-1.htm");
end
