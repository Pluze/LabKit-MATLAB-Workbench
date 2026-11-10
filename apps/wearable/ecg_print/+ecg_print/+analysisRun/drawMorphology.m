function drawMorphology(axesById, model)
%DRAWMORPHOLOGY Selected aligned beats, aligned ECGNExT noise, then all templates.
ids = ["selected","noise","all"];
for id=ids
    ax=axesById.(id);
    labkit.app.plot.clearAxes(ax,ResetScale=true);
    legend(ax,'off');grid(ax,'on');ylabel(ax,model.unit);
    xlabel(ax,'Aligned time relative to R (s)');
end
ax=axesById.selected;hold(ax,'on');
for k=1:numel(model.beatNumbers)
    line=plot(ax,model.time,model.beats(k,:), ...
        'Color',[.65 .75 .85],'DisplayName',sprintf('Beat %d',model.beatNumbers(k)));
    line.DataTipTemplate.DataTipRows(end+1)= ...
        dataTipTextRow('Beat',repmat(model.beatNumbers(k),size(model.time)));
end
plot(ax,model.time,model.template,'Color',[.85 .325 .098], ...
    'LineWidth',1.8,'DisplayName','Final median');
hold(ax,'off');title(ax,sprintf('Window %d · template and all aligned beats',model.window));
ax=axesById.noise;hold(ax,'on');
for k=1:numel(model.noiseBeats)
    beat=model.noiseBeats(k);
    line=plot(ax,beat.time,beat.values,'Color',[.466 .674 .188], ...
        'DisplayName',sprintf('Beat %d',beat.beat));
    line.DataTipTemplate.DataTipRows(end+1)= ...
        dataTipTextRow('Beat',repmat(beat.beat,size(beat.time)));
    line.DataTipTemplate.DataTipRows(end+1)= ...
        dataTipTextRow('SNR window',repmat(beat.sourceWindow,size(beat.time)));
end
hold(ax,'off');title(ax,sprintf('Window %d · aligned detrended noise used for SNR',model.window));
ax=axesById.all;hold(ax,'on');
colors=lines(max(1,model.windowCount));
for k=1:numel(model.templates)
    curve=model.templates(k);width=1;
    if curve.window==model.window,width=2.2;end
    line=plot(ax,curve.time,curve.values,'Color',colors(curve.window,:), ...
        'LineWidth',width,'DisplayName',sprintf('Window %d',curve.window));
    line.DataTipTemplate.DataTipRows(end+1)= ...
        dataTipTextRow('Window',repmat(curve.window,size(curve.time)));
end
hold(ax,'off');title(ax,'All windows · final templates (selected: thick)');
pairedAxes=[axesById.selected axesById.noise];
ecg_print.analysisRun.linkTimeAxes(pairedAxes,~isempty(model.time));
if ~isempty(model.time)
    low=min(model.time);high=max(model.time);
    for k=1:numel(model.noiseBeats)
        low=min(low,min(model.noiseBeats(k).time));
        high=max(high,max(model.noiseBeats(k).time));
    end
    xlim(axesById.selected,[low high]);
end
end
