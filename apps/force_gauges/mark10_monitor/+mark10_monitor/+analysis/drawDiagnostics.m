function drawDiagnostics(axesById, model)
%DRAWDIAGNOSTICS Render the same committed analysis in-panel or in a managed window.
mark10_monitor.analysis.drawOverview(axesById,model);
mark10_monitor.analysis.draw(axesById,model);
ax=axesById.contact; cla(ax); hold(ax,"on");
e=model.estimate;
if ~isempty(e)
    plot(ax,e.fitGap_mm,e.fitForce_N,'.',DisplayName="Low-force fit samples");
    xx=[min([e.fitGap_mm;e.length_mm]);max([e.fitGap_mm;e.length_mm])];
    plot(ax,xx,e.slope*xx+e.intercept,'-',DisplayName="Zero-force extrapolation");
    plot(ax,e.length_mm,0,'o',DisplayName="Extrapolated length");
    xline(ax,e.thresholdLength_mm,':',"Threshold length",HandleVisibility="off");
    label="Current input (unconfirmed)";
    if model.geometryConfirmed, label="Confirmed length"; end
    xline(ax,model.gaugeLength_mm,'--',label,HandleVisibility="off");
    legend(ax,"show",Location="best");
    title(ax,compose("Contact: %.6g mm; R2 %.4g; n=%d",e.length_mm,e.rSquared,e.count),Interpreter="none");
else
    text(ax,0.5,0.5,"No current contact fit; use measured length or estimate again", ...
        Units="normalized",HorizontalAlignment="center",Interpreter="none");
    title(ax,"Contact estimate unavailable / needs updating");
end
xlabel(ax,"Gap (mm)"); ylabel(ax,"Loading force magnitude (N)"); grid(ax,"on"); hold(ax,"off");
end
