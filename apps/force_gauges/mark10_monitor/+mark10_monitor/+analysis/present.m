function view = present(a,kind,filename)
%PRESENT Assemble bounded analysis models and reflect current result validity.
view=labkit.app.view.Snapshot();
ids=["analysisForceZero","analysisTravelZero", ...
    "contactAnchor","analysisStart","analysisEnd","gaugeLength", ...
    "specimenWidth","specimenThickness","specimenRadius","specimenArea"];
fields=["forceZeroDraft_N","travelZeroDraft_mm", ...
    "contactTime_s","timeStart_s","timeEnd_s","gaugeLength_mm", ...
    "width_mm","thickness_mm","radius_mm","area_mm2"];
for k=1:numel(ids), view=view.value(ids(k),a.(fields(k))); end
view=view.value("geometryConfirmed",a.geometryConfirmed);
view=view.value("modulusUnit",a.modulusUnit);
view=view.value("crossSectionMode",a.crossSectionMode);
view=view.value("excludeGlitches",a.excludeGlitches);
view=view.enabled("specimenWidth",a.crossSectionMode=="Length x width");
view=view.enabled("specimenThickness",a.crossSectionMode=="Length x width");
view=view.enabled("specimenRadius",a.crossSectionMode=="Radius");
view=view.enabled("specimenArea",a.crossSectionMode=="Area");
view=view.enabled("deleteStrainWindow",~isempty(a.windows));
view=view.text("glitchStatus",a.glitchStatus);
view=view.text("lengthEstimateStatus",a.lengthEstimateStatus);
view=view.text("contactHelp","Current test: "+kind+". Change Test type in section 1 if needed. Enter one approximate contact time; the App selects the local fit automatically. Review and confirm the estimated length.");
view=view.text("analysisStatus",a.status);
view=view.text("analysisExportStatus",a.exportStatus);
view=view.text("analysisRangeStatus",compose("Record %.6g–%.6g s; analyzing %.6g–%.6g s. Contact estimation uses the recording independently.",a.sourceRange_s(1),a.sourceRange_s(2),a.timeStart_s,a.timeEnd_s));
view=view.text("appliedZeroStatus",compose("Applied: force %.6g N; closure offset %.6g mm",a.forceZero_N,a.travelZero_mm));
view=view.text("analysisZeroGuidance","Travel 0 mm = fully closed fixture in every mode. Use unloaded force for force zero. Initial specimen length is a separate, reviewed quantity.");
view=view.tableData("strainWindows",a.windows,Columns=["Use","Name","From %","To %"],ColumnEditable=true);
[displayRows,modulusUnit]=mark10_monitor.analysis.resultTable(a.resultRows,a.modulusUnit);
columns=["Branch","Window","E ("+modulusUnit+")","R²","n","From %","To %", ...
    "Coverage %","Notes","Actual from %","Actual to %","Phase"];
order=[1 3 9 10 8 4 5 11 12 6 7 2];
if kind~="Cyclic",order=order(2:end-1);columns=columns(2:end-1);end
view=view.tableData("modulusResults",displayRows(:,order),Columns=columns);
model=a; model.filename=filename; model.experimentType=kind;
view=view.text("modulusPlot",mark10_monitor.plotTitle("Stress-Strain and Window Fits",filename));
view=view.text("analysisOverview",mark10_monitor.plotTitle("Recording and Analysis Time Range",filename));
view=view.text("diagnosticPlot",mark10_monitor.plotTitle("Analysis Diagnostics",filename));
view=view.renderPlot("modulusPlot",model,ViewRevision=a.curveRevision);
view=view.renderPlot("analysisOverview",model,ViewRevision=join(string([a.sourceRevision a.forceZero_N a.travelZero_mm a.timeStart_s a.timeEnd_s a.contactTime_s a.curveRevision]),"|"));
view=view.renderPlot("diagnosticPlot",model,ViewRevision=a.curveRevision,WindowRequest=a.diagnosticRequest);
end
