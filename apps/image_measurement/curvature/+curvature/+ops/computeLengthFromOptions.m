% App-owned curvature length options adapter. Expected caller: curvature tests
% and advanced debug code. Inputs are curve points plus app option struct;
% output is the same length result returned by computeCurveLength. No side effects.
function lengthResult = computeLengthFromOptions(xPix, yPix, opts)
%COMPUTELENGTHFROMOPTIONS Measure curve length from app-style option fields.

    if nargin < 3
        opts = struct();
    end

    calibration = curvature.ops.scaleOptionsFromStruct(opts);
    lengthResult = curvature.ops.computeCurveLength(xPix, yPix, calibration);
end
