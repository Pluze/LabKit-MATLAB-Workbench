function drawRecording(axesById,model)
%DRAWRECORDING Show original file and the pending strict analysis interval.
ax=axesById.main;labkit.app.plot.clearAxes(ax,ResetScale=true);
plot(ax,model.time,model.values,'Color',[.45 .45 .45]);hold(ax,'on');
if ~isempty(model.time)
    mask=model.time>=model.range(1)&model.time<=model.range(2);
    plot(ax,model.time(mask),model.values(mask),'Color',[0 .447 .741]);
    xline(ax,model.range(1),'--','Start');xline(ax,model.range(2),'--','End');
    if model.time(end)>model.time(1),xlim(ax,[model.time(1) model.time(end)]);end
end
hold(ax,'off');title(ax,'Original recording · blue interval enters analysis');
xlabel(ax,'File time (s)');ylabel(ax,model.unit);grid(ax,'on');
end
