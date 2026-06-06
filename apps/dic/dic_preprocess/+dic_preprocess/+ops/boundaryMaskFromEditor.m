% Expected caller: DIC preprocess runner and direct unit tests. Inputs are
% current mask anchors, image size, boundary style, and optional anchor-editor
% handle. Outputs are a boundary mask and success flag. Side effects: none unless
% the editor handle computes its current curve points.

function [boundaryMask, ok] = boundaryMaskFromEditor(maskPoints, imageSize, boundaryStyle, maskEditor)
%BOUNDARYMASKFROMEDITOR Build the current DIC preprocess ROI boundary mask.

    ok = false;
    boundaryMask = [];
    if size(maskPoints, 1) < 3
        return;
    end
    if ~isempty(maskEditor)
        curve = maskEditor.curvePoints();
        boundaryMask = dic_preprocess.ops.maskFromCurve(curve, imageSize);
    else
        boundaryMask = dic_preprocess.ops.boundaryMaskImage( ...
            maskPoints, imageSize, boundaryStyle);
    end
    ok = true;
end
