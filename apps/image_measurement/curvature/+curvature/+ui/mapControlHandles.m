% Expected caller: curvature.run after labkit.ui.app.create. Inputs are the
% UI 3.0 registry and the scale-bar tool. Output is the app's control handle
% struct used by the existing runner logic. Side effects: none.
function controls = mapControlHandles(ui, scaleTool)
%MAPCONTROLHANDLES Map UI 3.0 adapters to curvature control handles.

    controls = struct();
    controls.txtPointCount = ui.controls.pointCount.valueHandle;
    controls.btnStartCurve = ui.controls.startCurveEdit.button;
    controls.btnUndoPoint = ui.controls.undoCurvePoint.button;
    controls.btnClearCurve = ui.controls.clearCurve.button;
    controls.scaleTool = scaleTool;
    controls.chkDensify = ui.controls.densify.valueHandle;
    controls.edtDenseN = ui.controls.densePointCount.valueHandle;
    controls.chkShowDense = ui.controls.showDensePoints.valueHandle;
    controls.btnFit = ui.controls.fitCurvature.button;
    controls.btnMeasureLength = ui.controls.measureCurveLength.button;
    controls.btnExportCSV = ui.controls.exportCsv.button;
    controls.btnExportOverlay = ui.controls.exportOverlay.button;
    controls.resultTable = ui.controls.resultTable.table;
    controls.txtDetails = ui.controls.detailsText.textArea;
    controls.txtLog = ui.controls.appLog.textArea;
end
