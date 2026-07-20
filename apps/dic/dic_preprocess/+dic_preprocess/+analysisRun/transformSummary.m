% Expected caller: DIC preprocess runner and direct unit tests. Inputs are a
% MATLAB transform object or 3x3 transform matrix plus reference and moving
% image sizes. Output is the alignment detail text shown by the app. Side
% effects: none.

function lines = transformSummary(tform, referenceSize, movingSize)
%TRANSFORMSUMMARY Build alignment transform detail text.

    T = transformMatrix(tform);
    lines = { ...
        sprintf('Reference size: %d x %d', referenceSize(1), referenceSize(2)), ...
        sprintf('Moving size: %d x %d', movingSize(1), movingSize(2)), ...
        'Rigid transform matrix:', ...
        sprintf('[%.6g %.6g %.6g]', T(1, 1), T(1, 2), T(1, 3)), ...
        sprintf('[%.6g %.6g %.6g]', T(2, 1), T(2, 2), T(2, 3)), ...
        sprintf('[%.6g %.6g %.6g]', T(3, 1), T(3, 2), T(3, 3))};
end

function T = transformMatrix(tform)
    if isnumeric(tform) && isequal(size(tform), [3 3])
        T = tform;
    elseif isstruct(tform) && isfield(tform, 'T')
        T = tform.T;
    elseif isstruct(tform) && isfield(tform, 'A')
        T = tform.A;
    elseif isprop(tform, 'T')
        T = tform.T;
    elseif isprop(tform, 'A')
        T = tform.A;
    else
        T = eye(3);
    end
end
