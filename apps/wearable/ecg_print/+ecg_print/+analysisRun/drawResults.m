function drawResults(axesById,model)
%DRAWRESULTS ECG and time-indexed per-beat NST-centered noise, QRS amplitude and SNR.
ids=["wave","noise","peak","ratio"];
axes=arrayfun(@(id)axesById.(id),ids);linkaxes(axes,'off');
for id=ids,labkit.app.plot.clearAxes(axesById.(id),ResetScale=true);end
if model.showRecording
    ecg_print.analysisRun.drawRecording(struct('main',axesById.wave),model.recording);
else
    plot(axesById.wave,model.time,model.ecg,'Color',[0 .447 .741]);hold(axesById.wave,'on');
    scatter(axesById.wave,model.peakTime,model.peakValues,12,[.8 .2 .2],'filled');
    hold(axesById.wave,'off');title(axesById.wave,'Original ECG + R peaks');
end
if ~isempty(model.beats) && ~model.showRecording
    t=model.beats;
    plot(axesById.noise,t.RTime,t.NoiseRMS,'.-','LineWidth',1.15,'Color',[.494 .184 .556]);
    plot(axesById.ratio,t.RTime,t.QRSNoiseDb,'.-','LineWidth',1.15,'Color',[.466 .674 .188]);
    plot(axesById.peak,t.RTime,t.QRSPeakToPeak,'.-','LineWidth',1.15,'Color',[0 .447 .741]);
end
title(axesById.noise,'Noise RMS per beat (NST 1 s centering)');ylabel(axesById.noise,model.unit);
title(axesById.peak,'Signal peak-to-peak per beat');ylabel(axesById.peak,model.unit);
title(axesById.ratio,'SNR per beat (same-beat QRS p-p / noise RMS)');
ylabel(axesById.ratio,'dB');
ylabel(axesById.wave,model.unit);
for id=ids
    ax=axesById.(id);grid(ax,'on');xlabel(ax,'ROI time (s)');
    lines=findall(ax,'Type','line');chunks=cell(numel(lines),1);
    for k=1:numel(lines),chunks{k}=lines(k).YData(:);end
    values=vertcat(chunks{:});values=values(isfinite(values));
    if ~isempty(values)
        lo=min(values);hi=max(values);margin=max(eps,.05*max(hi-lo,eps));
        ylim(ax,[lo-margin hi+margin]);
    end
end
if ~model.showRecording
    linkaxes(axes,'x');
    if ~isempty(model.time)&&model.time(end)>model.time(1)
        xlim(axesById.wave,[model.time(1) model.time(end)]);
    end
else
    xlabel(axesById.wave,'File time (s)');
end
end
