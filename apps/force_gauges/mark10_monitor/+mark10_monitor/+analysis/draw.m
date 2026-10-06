function draw(axesById, model)
%DRAW Show current engineering curve and the selected branch-window fit.
ax=axesById.stressStrain;
cla(ax); hold(ax,"on");
if model.curveReady
    curve=model.curve;
    for segment=unique(curve.segment).'
        indices=find(curve.segment==segment);
        indices=indices(unique(round(linspace(1,numel(indices),min(2000,numel(indices))))));
        plot(ax,100*curve.strain(indices),curve.stress_MPa(indices),Color=[0.2 0.45 0.7], ...
            DisplayName="Engineering curve",HandleVisibility="off");
    end
    for k=1:numel(model.fitLines)
        line=model.fitLines(k);
        if line.row~=model.selectedResult, continue; end
        plot(ax,line.pointsX,line.pointsY,'.',Color=[0.85 0.4 0.1],DisplayName="Selected window samples");
        plot(ax,line.strain_percent,line.stress_MPa,'-',LineWidth=2,Color=[0.2 0.6 0.3],DisplayName="Window least-squares fit");
    end
    if ~isempty(model.fitLines), legend(ax,"show",Location="best"); end
else
    text(ax,0.5,0.5,"Curve needs updating",Units="normalized",HorizontalAlignment="center");
end
hold(ax,"off"); grid(ax,"on");
convention="tension + / compression -";
if model.experimentType=="Compression", convention="compression +"; end
xlabel(ax,"Engineering strain (%), "+convention); ylabel(ax,"Engineering stress (MPa)");
title(ax,mark10_monitor.plotTitle("Stress-Strain",model.filename),Interpreter="none");
end
