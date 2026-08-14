function draw(axesById, model)
%DRAW Render branch-local stress-strain curves, fits, and summary.
ax = axesById.stressStrain;
delete(allchild(ax));
cla(ax, "reset");
hold(ax, "on");
plot(ax, model.strain_percent, model.stress_MPa, ...
    Color=[0 0.4470 0.7410], LineWidth=1.0, ...
    DisplayName="Branch data", HitTest="off", PickableParts="none");
acceptedNamed = false;
reviewNamed = false;
for k = 1:numel(model.fitLines)
    fit = model.fitLines(k);
    color = [0.2 0.65 0.25];
    style = "-";
    if ~fit.accepted
        color = [0.85 0.325 0.098];
        style = "--";
    end
    name = "";
    showInLegend = false;
    if fit.accepted && ~acceptedNamed
        name = "Accepted linear fit";
        showInLegend = true;
        acceptedNamed = true;
    elseif ~fit.accepted && ~reviewNamed
        name = "Fit requiring review";
        showInLegend = true;
        reviewNamed = true;
    end
    fitHandle = plot(ax, fit.strain_percent, fit.stress_MPa, ...
        LineWidth=2, LineStyle=style, Color=color, ...
        Marker="o", MarkerSize=5, DisplayName=name, ...
        HandleVisibility="on", HitTest="off", PickableParts="none");
    if ~showInLegend
        fitHandle.Annotation.LegendInformation.IconDisplayStyle = "off";
    end
end
hold(ax, "off");
xlabel(ax, "Engineering strain (%)");
ylabel(ax, "Engineering stress (MPa)");
title(ax, "Per-branch stress-strain fits");
grid(ax, "on");
if ~isempty(model.fitLines), legend(ax, "show", Location="best"); end

summaryAxes = axesById.modulusSummary;
delete(allchild(summaryAxes));
cla(summaryAxes, "reset");
summaryAxes.Visible = "off";
text(summaryAxes, 0.02, 0.98, model.summary, Units="normalized", ...
    VerticalAlignment="top", Interpreter="none", FontName="monospaced", ...
    FontSize=12, HitTest="off");
end
