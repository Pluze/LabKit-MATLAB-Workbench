% Expected caller: DIC preprocess runner. Inputs are the current
% reference/moving images and matched fixed/moving control points. Outputs are
% the rigidly aligned moving image and 3x3 transform matrix. Side effects: none.

function [alignedImage, tformRigid] = alignMovingToReference(referenceImage, movingImage, fixedPoints, movingPoints)
%ALIGNMOVINGTOREFERENCE Rigidly align the moving image to the reference image.

    [R, t] = rigidTransformFromPoints(fixedPoints, movingPoints);
    T = [R(1,1) R(1,2) 0; ...
         R(2,1) R(2,2) 0; ...
         t(1)   t(2)   1];
    tformRigid = T;

    alignedImage = dic_preprocess.analysisRun.applyRigidTransform( ...
        referenceImage, movingImage, T);
end

function [R, t] = rigidTransformFromPoints(fixedPoints, movingPoints)
    fixedPoints = double(fixedPoints);
    movingPoints = double(movingPoints);
    fixedCenter = mean(fixedPoints, 1);
    movingCenter = mean(movingPoints, 1);
    fixedCentered = fixedPoints - fixedCenter;
    movingCentered = movingPoints - movingCenter;
    H = movingCentered.' * fixedCentered;
    [U, ~, V] = svd(H);
    R = U * V.';
    if det(R) < 0
        V(:, end) = -V(:, end);
        R = U * V.';
    end
    t = fixedCenter - movingCenter * R;
end
