function view = present(state)
points=state.project.annotations.curvePoints; image=state.session.cache.image;
fit=state.project.results.fit; length=state.project.results.length;
view=labkit.app.view.Snapshot();
view=view.enabled("undoCurve",~isempty(points)); view=view.enabled("clearCurve",~isempty(points));
view=view.enabled("fitCurvature",size(points,1)>=3); view=view.enabled("measureLength",size(points,1)>=2);
view=view.enabled("placeScaleBar",~isempty(image) && state.project.annotations.calibration.isCalibrated);
view=view.enabled("exportCsv",fit.ok||length.ok); view=view.enabled("exportOverlay",~isempty(image));
data={"Curve points",size(points,1);"Fit",string(fit.ok);"Length",string(length.ok)};
view=view.tableData("resultTable",data,Columns=["Metric" "Value"]); view=view.text("details","Edit the curve directly on the image.");
view=view.renderPlot("preview",struct("image",image,"points",points,"path",curvature.curvePreview.visiblePath(points,image)));
sizeValue=[]; if ~isempty(image),sizeValue=size(image);end
view=view.anchorPath("curve",points,ImageSize=sizeValue,Enabled=~isempty(image));
view=view.scaleReference("scaleReference",state.project.annotations.calibration.referenceLine,ImageSize=sizeValue,Enabled=~isempty(image));
end
