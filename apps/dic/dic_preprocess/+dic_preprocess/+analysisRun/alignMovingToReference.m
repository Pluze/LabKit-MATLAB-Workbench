function [alignedImage, tformRigid] = alignMovingToReference(referenceImage, movingImage, fixedPoints, movingPoints)
%ALIGNMOVINGTOREFERENCE Fit and apply a rigid transform from matched points.
%
% Usage:
%   [alignedImage, transform] = ...
%       dic_preprocess.analysisRun.alignMovingToReference( ...
%       referenceImage, movingImage, fixedPoints, movingPoints)
%
% Inputs:
%   referenceImage - Reference image whose height and width define the output
%       canvas.
%   movingImage - Numeric grayscale or multichannel image to transform.
%   fixedPoints - N-by-2 [x y] coordinates in referenceImage.
%   movingPoints - N-by-2 corresponding [x y] coordinates in movingImage.
%       Use the same number and order of points as fixedPoints. At least two
%       distinct pairs are needed to constrain a 2-D rigid transform.
%
% Outputs:
%   alignedImage - movingImage resampled onto the reference canvas. It has the
%       moving image class and channel count; pixels outside the source are 0.
%   tformRigid - Three-by-three row-vector homogeneous transform, shown as
%       transform in the usage syntax. A moving coordinate maps to reference
%       coordinates as [x y 1]*tformRigid.
%
% Description:
%   The function uses the least-squares orthogonal Procrustes solution for one
%   rotation and translation; reflection is explicitly rejected. It does not
%   estimate scale or shear. Resampling is delegated to applyRigidTransform.
%
% Example:
%   reference = zeros(12, 12);
%   moving = zeros(12, 12); moving(4:6, 3:5) = 1;
%   movingPoints = [3 4; 5 4; 3 6];
%   fixedPoints = movingPoints + [2 1];
%   [aligned, transform] = ...
%       dic_preprocess.analysisRun.alignMovingToReference( ...
%       reference, moving, fixedPoints, movingPoints);
%   assert(isequal(size(aligned), size(reference)))
%   assert(norm([movingPoints ones(3,1)]*transform - ...
%       [fixedPoints ones(3,1)], "fro") < 1e-10)
%
% See also dic_preprocess.analysisRun.applyRigidTransform,
%   dic_preprocess.analysisRun.autoAlignMovingToReference

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
