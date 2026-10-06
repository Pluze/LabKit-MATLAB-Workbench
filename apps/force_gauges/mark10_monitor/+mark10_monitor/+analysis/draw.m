function draw(axesById, model)
%DRAW Display every enabled region and every computable branch-window fit.
ax=axesById.stressStrain;
delete(findall(ax,'Type','constantline'));cla(ax);legend(ax,'off');hold(ax,'on');
if model.curveReady
    curve=model.curve;
    for segment=unique(curve.segment).'
        indices=find(curve.segment==segment);
        indices=indices(unique(round(linspace(1,numel(indices),min(2000,numel(indices))))));
        plot(ax,100*curve.strain(indices),curve.stress_MPa(indices),Color=[.55 .55 .55]);
    end
    colors=lines(max(1,size(model.windows,1)));bounds=paddedLimits(curve.stress_MPa);
    xBounds=[100*curve.strain;NaN(2*size(model.windows,1),1)];
    for w=1:size(model.windows,1)
        if ~model.windows{w,1},continue;end
        lo=model.windows{w,3};hi=model.windows{w,4};
        xBounds(numel(curve.strain)+(2*w-1:2*w))=[lo;hi];
        patch(ax,[lo hi hi lo],bounds([1 1 2 2]),colors(w,:), ...
            FaceAlpha=.07,EdgeColor="none",Tag="mark10Region"+w);
        text(ax,(lo+hi)/2,bounds(2),string(model.windows{w,2}), ...
            Color=colors(w,:),VerticalAlignment="top",HorizontalAlignment="center",Interpreter="none",FontSize=9);
    end
    [rows,unit]=mark10_monitor.analysis.resultTable(model.resultRows,model.modulusUnit);
    fitHandles=gobjects(1,numel(model.fitLines));
    for k=1:numel(model.fitLines)
        fit=model.fitLines(k);color=colors(fit.windowIndex,:);width=1.8;
        if fit.row==model.selectedResult,width=3;end
        plot(ax,fit.pointsX,fit.pointsY,'.',Color=color);
        row=rows(fit.row,:);
        label=compose("%s | %.3g–%.3g%% | E %.4g %s",string(row{3}),row{4},row{5},row{9},unit);
        if model.experimentType=="Cyclic",label=label+" | branch "+row{1};end
        fitHandles(k)=plot(ax,fit.strain_percent,fit.stress_MPa,'-',LineWidth=width, ...
            Color=color,DisplayName=label,Tag="mark10WindowFit"+fit.row);
    end
    if ~isempty(fitHandles),legend(ax,fitHandles,Location="best",Interpreter="none");end
else
    text(ax,.5,.5,"Curve needs updating",Units="normalized",HorizontalAlignment="center");
end
hold(ax,"off");grid(ax,"on");
if model.curveReady,xlim(ax,paddedLimits(xBounds));ylim(ax,bounds);end
convention="tension + / compression -";
if model.experimentType=="Compression",convention="compression +";end
xlabel(ax,"Engineering strain (%), "+convention);ylabel(ax,"Engineering stress (MPa)");
title(ax,mark10_monitor.plotTitle("All Strain Windows",model.filename),Interpreter="none");
end

function bounds=paddedLimits(values)
values=values(isfinite(values));
if isempty(values),bounds=[0 1];return;end
bounds=[min(values),max(values)];
margin=.04*diff(bounds);
if margin==0,margin=.04*max(1,max(abs(bounds)));end
bounds=bounds+[-margin margin];
end
