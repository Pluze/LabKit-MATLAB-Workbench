function statistics = beatStatistics(beats,unit)
%BEATSTATISTICS Mean and sample variance over finite complete-beat estimates.
%   statistics = ecg_print.analysisRun.beatStatistics(beats,unit) returns
%   NoiseRMS, QRSPeakToPeak and QRSNoiseDb rows. Only complete rows with finite
%   values contribute. Variance uses n-1; fewer than two values gives NaN.
%   These untrimmed per-beat summaries are not NST aggregate calibration.
fields=["NoiseRMS";"QRSPeakToPeak";"QRSNoiseDb"];
Mean=NaN(3,1);Variance=Mean;N=zeros(3,1);
for k=1:3
    if isempty(beats),continue;end
    values=beats.(fields(k));
    values=values(beats.Status=="complete" & isfinite(values));
    N(k)=numel(values);
    if N(k)>0,Mean(k)=mean(values);end
    if N(k)>1,Variance(k)=var(values,0);end
end
Unit=[string(unit);string(unit);"dB"];VarianceUnit=Unit+"^2";
statistics=table(fields,Mean,Variance,N,Unit,VarianceUnit, ...
    'VariableNames',{'Metric','Mean','Variance','N','Unit','VarianceUnit'});
end
