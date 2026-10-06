function drawOverview(axesById, model)
%DRAWOVERVIEW Complete source overview; shaded analysis range preserves time.
fields=["force_N","gap_mm"]; ids=["forceTime","travelTime"];
labels=["Force (N)","Gap (mm)"]; offsets=[model.forceZero_N model.travelZero_mm];
for k=1:2
    ax=axesById.(ids(k)); cla(ax); hold(ax,"on");
    plot(ax,model.overview.time_s,model.overview.(fields(k))-offsets(k), ...
        Color=[0.2 0.45 0.7],DisplayName="Recording");
    if ~isempty(model.overview.time_s)
        y=ylim(ax); x=[model.timeStart_s model.timeEnd_s];
        patch(ax,[x fliplr(x)],[y(1) y(1) y(2) y(2)],[0.2 0.65 0.35], ...
            FaceAlpha=0.12,EdgeColor="none",DisplayName="Analysis time");
        xline(ax,model.referenceStart_s,':',"Reference start",HandleVisibility="off");
        xline(ax,model.referenceEnd_s,':',"Reference end",HandleVisibility="off");
        p=model.excludedPreview;
        if ~isempty(p.time_s)
            plot(ax,p.time_s,p.(fields(k))-offsets(k),'rx',DisplayName="Glitch candidates");
        end
    end
    hold(ax,"off"); grid(ax,"on"); xlabel(ax,"Recorded time (s)"); ylabel(ax,labels(k));
    title(ax,mark10_monitor.plotTitle(labels(k)+" / time",model.filename),Interpreter="none");
end
end
