% Expected caller: DIC preprocess startup action after framework UI creation. Input is
% the UI 5 registry. Output is the app's legacy-named control handle struct
% used by existing app-owned interaction helpers. Side effects: none.
function controls = mapControlHandles(ui)
%MAPCONTROLHANDLES Map UI 5 adapters to DIC preprocess control handles.

    controls = struct();
    controls.ddPreview = ui.controls.previewMode.valueHandle;
    controls.btnStartPointMatching = ui.controls.startPointMatching.button;
    controls.btnApplyPointAlignment = ui.controls.applyPointAlignment.button;
    controls.btnCancelPointMatching = ui.controls.cancelPointMatching.button;
    controls.btnUndoPointPair = ui.controls.undoPointPair.button;
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
