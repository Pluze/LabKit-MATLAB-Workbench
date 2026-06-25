% Expected caller: DIC preprocess runner after labkit.ui.app.create. Input is
% the UI 3.0 registry. Output is the app's legacy-named control handle struct
% used by existing app-owned interaction helpers. Side effects: none.
function controls = mapControlHandles(ui)
%MAPCONTROLHANDLES Map UI 3.0 adapters to DIC preprocess control handles.

    controls = struct();
    controls.ddPreview = ui.controls.previewMode.valueHandle;
    controls.btnAlign = ui.controls.align.button;
    controls.btnAutoAlign = ui.controls.autoAlign.button;
    controls.btnCrop = ui.controls.startCropRoi.button;
    controls.btnApplyCrop = ui.controls.applyCropRoi.button;
    controls.btnCancelCrop = ui.controls.cancelCropRoi.button;
    controls.btnUndoEdit = ui.controls.undoEdit.button;
    controls.btnSaveCurrent = ui.controls.saveCurrentImages.button;
    controls.btnResetCurrent = ui.controls.resetToOriginals.button;
    controls.btnStartMask = ui.controls.startMaskEdit.button;
    controls.ddBoundaryStyle = ui.controls.boundaryStyle.valueHandle;
    controls.btnPreviewMask = ui.controls.previewMaskRoi.button;
    controls.btnUnionMask = ui.controls.addBoundaryToMask.button;
    controls.btnSubtractMask = ui.controls.subtractBoundaryFromMask.button;
    controls.btnUndoMask = ui.controls.undoMaskAnchor.button;
    controls.btnUndoMaskEdit = ui.controls.undoMaskEdit.button;
    controls.btnClearBoundary = ui.controls.clearMaskBoundary.button;
    controls.btnClearMask = ui.controls.clearMaskCanvas.button;
    controls.btnSaveMask = ui.controls.saveMask.button;
end
