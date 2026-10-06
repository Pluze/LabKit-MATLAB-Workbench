function drawOverview(axesById, model)
%DRAWOVERVIEW Explain analysis/contact intervals without accumulating markers.
fields=["force_N","gap_mm"];ids=["forceTime","travelTime"];
labels=["Force (N)","Gap (mm)"];offsets=[model.forceZero_N model.travelZero_mm];
for k=1:2
    if ~isfield(axesById,ids(k)),continue;end
    ax=axesById.(ids(k));
    % cla alone does not remove HandleVisibility-off ConstantLine objects.
    delete(findall(ax,'Type','constantline'));cla(ax);legend(ax,'off');hold(ax,'on');
    line=plot(ax,model.overview.time_s,model.overview.(fields(k))-offsets(k), ...
        Color=[.2 .45 .7],DisplayName="Full recording");
    if ~isempty(model.overview.time_s)
        values=model.overview.(fields(k))-offsets(k);values=values(isfinite(values));
        y=[min(values) max(values)];margin=.05*diff(y);
        if margin==0,margin=.05*max(1,max(abs(y)));end
        y=y+[-margin margin];ylim(ax,y);
        xlim(ax,[min(model.overview.time_s) max(model.overview.time_s)]+[-1 1]*eps(max(1,max(abs(model.overview.time_s)))));
        x=[model.timeStart_s model.timeEnd_s];
        analysis=patch(ax,[x fliplr(x)],y([1 1 2 2]),[.2 .65 .35], ...
            FaceAlpha=.1,EdgeColor="none",DisplayName="Analysis interval");
        reference=gobjects(0);
        if ~isempty(model.estimate)
            e=model.estimate;x=e.referenceTime_s(e.fitIndices([1 end])).';
            reference=patch(ax,[x fliplr(x)],y([1 1 2 2]),[.95 .65 .15], ...
                FaceAlpha=.15,EdgeColor="none",DisplayName="Automatic contact-fit interval");
        end
        anchor=xline(ax,model.contactTime_s,':',Color=[.65 .2 .65], ...
            DisplayName="Specified contact time");
        p=model.excludedPreview;
        if ~isempty(p.time_s),plot(ax,p.time_s,p.(fields(k))-offsets(k),'rx');end
        legend(ax,[line analysis reference anchor],Location="best",Interpreter="none",FontSize=8);
    end
    hold(ax,'off');grid(ax,'on');xlabel(ax,"Recorded time (s)");ylabel(ax,labels(k));
    title(ax,{char(labels(k)+" — time"),char(model.filename)},Interpreter="none",FontSize=9);
end
end
