% Expected caller: Image Enhance runner. Inputs are app state and selected
% tool label. Output centralizes tool button enablement and status text.
function state = toolAvailability(S, toolKind)
    hasImages = ~isempty(S.project.inputs.sources) && ...
        ~isempty(S.session.cache.item);
    batchMode = S.project.parameters.batchMode;
    current = image_enhance.appState.emptyAnnotation();
    if hasImages
        current = S.project.annotations.items( ...
            S.session.selection.currentIndex);
    end
    isWhiteRoi = strcmpi(regexprep(char(string(toolKind)), ...
        '[^a-zA-Z0-9]', ''), 'whiteroicalibration');
    hasRoi = false;
    if hasImages
        roi = double(current.whiteRoi);
        hasRoi = numel(roi) == 4 && all(isfinite(roi)) && ...
            all(roi(3:4) > 0);
    end

    state = struct();
    state.isWhiteRoi = isWhiteRoi;
    state.canSetWhiteRoi = hasImages && ~batchMode && isWhiteRoi;
    state.canApply = hasImages && (~isWhiteRoi || (~batchMode && hasRoi));
    state.canPreviewPending = state.canApply && ~isWhiteRoi;
    if ~hasImages
        state.status = 'Select an image, choose a tool, then apply it to history.';
    elseif isWhiteRoi && batchMode
        state.status = 'White ROI calibration is per-image only. Switch off batch shared processing.';
    elseif isWhiteRoi && ~hasRoi
        state.status = 'Set a white ROI for this image before applying.';
    elseif isWhiteRoi
        state.status = 'White ROI set for this image. Apply to this image history.';
    elseif batchMode
        state.status = 'Batch mode: this tool will be shared by all loaded images.';
    else
        state.status = 'Per-image mode: this tool applies to the selected image only.';
    end
end
