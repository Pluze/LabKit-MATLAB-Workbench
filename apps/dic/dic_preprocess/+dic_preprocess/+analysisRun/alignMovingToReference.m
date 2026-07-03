% Expected caller: DIC preprocess runner. Inputs are the current
% reference/moving images and matched fixed/moving control points. Outputs are
% the rigidly aligned moving image and transform. Side effects: none.

function [alignedImage, tformRigid] = alignMovingToReference(referenceImage, movingImage, fixedPoints, movingPoints)
%ALIGNMOVINGTOREFERENCE Rigidly align the moving image to the reference image.

    origClass = class(movingImage);
    [~, ~, tr] = procrustes(fixedPoints, movingPoints, ...
        'Scaling', false, 'Reflection', false);

    R = tr.T;
    t = tr.c(1, :);
    T = [R(1,1) R(1,2) 0; ...
         R(2,1) R(2,2) 0; ...
         t(1)   t(2)   1];
    tformRigid = affine2d(T);

    Rfixed = imref2d(size(referenceImage(:, :, 1)));
    alignedImage = imwarp(movingImage, tformRigid, ...
        'OutputView', Rfixed, 'FillValues', 0);
    alignedImage = cast(alignedImage, origClass);
end
