% Expected caller: Image Enhance runner. Inputs are app state and selected
% tool label. Output centralizes tool button enablement and status text.
function state = toolAvailability(S, toolKind)
    hasImages = ~isempty(S.items);
    isWhiteRoi = image_enhance.ui.whiteRoiHelpers("isTool", toolKind);
    hasRoi = false;
    if hasImages
        hasRoi = image_enhance.ui.whiteRoiHelpers("hasRoi", S.items(S.currentIndex));
    end

    state = struct();
    state.isWhiteRoi = isWhiteRoi;
    state.canSetWhiteRoi = hasImages && ~S.batchMode && isWhiteRoi;
    state.canApply = hasImages && (~isWhiteRoi || (~S.batchMode && hasRoi));
    state.canPreviewPending = state.canApply && ~isWhiteRoi;
    if ~hasImages
        state.status = 'Select an image, choose a tool, then apply it to history.';
    elseif isWhiteRoi && S.batchMode
        state.status = 'White ROI calibration is per-image only. Switch off batch shared processing.';
    elseif isWhiteRoi && ~hasRoi
        state.status = 'Set a white ROI for this image before applying.';
    elseif isWhiteRoi
        state.status = 'White ROI set for this image. Apply to this image history.';
    elseif S.batchMode
        state.status = 'Batch mode: this tool will be shared by all loaded images.';
    else
        state.status = 'Per-image mode: this tool applies to the selected image only.';
    end
end
