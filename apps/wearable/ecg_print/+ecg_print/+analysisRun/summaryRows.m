function rows = summaryRows(result)
%SUMMARYROWS Report per-beat means, sample variances and counts.
rows = cell(0,4);
if isempty(result),return;end
s=result.statistics;
rows=cell(height(s),4);
names=["Noise RMS (NST-centered)";"QRS peak-to-peak";"SNR per beat (dB)"];
for k=1:height(s)
    rows(k,:)={char(names(k)),sprintf('%.5g',s.Mean(k)), ...
        sprintf('%.5g',s.Variance(k)),sprintf('%d',s.N(k))};
end
rows=[rows;{'Amplitude unit',char(result.unit),'',''}];
end
