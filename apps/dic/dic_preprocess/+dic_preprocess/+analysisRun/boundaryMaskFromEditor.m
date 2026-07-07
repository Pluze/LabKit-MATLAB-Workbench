% Expected caller: DIC preprocess runner and direct unit tests. Inputs are
% current mask anchors, image size, boundary style, and optional anchor-editor
% handle. Outputs are a boundary mask and success flag. Side effects: none unless
% the editor handle computes its current curve points.

function [boundaryMask, ok] = boundaryMaskFromEditor(maskPoints, imageSize, boundaryStyle, maskEditor)
%BOUNDARYMASKFROMEDITOR Build the current DIC preprocess ROI boundary mask.

    ok = false;
    boundaryMask = [];
    [maskPoints, hasLiveEditorPoints] = currentEditorPoints(maskPoints, maskEditor);
    if size(maskPoints, 1) < 3
        return;
    end
    [curve, hasEditorCurve] = currentEditorCurve(maskEditor);
    if hasLiveEditorPoints && hasEditorCurve && ~isempty(curve)
        boundaryMask = dic_preprocess.analysisRun.maskFromCurve(curve, imageSize);
    else
        boundaryMask = dic_preprocess.analysisRun.boundaryMaskImage( ...
            maskPoints, imageSize, boundaryStyle);
    end
    ok = true;
end

function [points, ok] = currentEditorPoints(fallbackPoints, maskEditor)
    ok = false;
    points = fallbackPoints;
    if isempty(maskEditor) || ~isstruct(maskEditor) || ...
            ~isfield(maskEditor, 'getPoints') || ~isa(maskEditor.getPoints, 'function_handle')
        return;
    end
    points = maskEditor.getPoints();
    ok = true;
end

function [curve, ok] = currentEditorCurve(maskEditor)
    ok = false;
    curve = [];
    if isempty(maskEditor) || ~isstruct(maskEditor) || ...
            ~isfield(maskEditor, 'curvePoints') || ~isa(maskEditor.curvePoints, 'function_handle')
        return;
    end
    curve = maskEditor.curvePoints();
    ok = true;
end
