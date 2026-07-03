% Expected caller: DIC preprocess runner and direct unit tests. Inputs are the
% current mask canvas, reference image, boundary mask, and operation label.
% Output is the updated uint8 mask canvas. Side effects: none.

function maskImage = applyBoundaryToMask(maskImage, referenceImage, boundaryMask, operation)
%APPLYBOUNDARYTOMASK Add or subtract a boundary from the DIC ROI mask canvas.

    maskImage = dic_preprocess.appState.maskCanvas(maskImage, referenceImage);
    if strcmp(string(operation), "add")
        maskImage = max(maskImage, boundaryMask);
    else
        maskImage(boundaryMask > 0) = 0;
    end
end
