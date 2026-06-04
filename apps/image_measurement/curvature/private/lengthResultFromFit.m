function lengthResult = lengthResultFromFit(fit)
%LENGTHRESULTFROMFIT Derive curve-length result from a fit result.
%
% Expected caller:
%   labkit_CurvatureMeasurement_app display/export helpers and app-private
%   result-table code.
%
% Inputs/outputs:
%   Fit struct in the app-owned result shape. Returns a length-result struct,
%   falling back to the default empty result when fit has no valid length.
%
% Side effects:
%   None.

    lengthResult = emptyLengthResult();
    if isstruct(fit) && isfield(fit, 'curveLength_px') && ...
            isfinite(fit.curveLength_px) && fit.curveLength_px >= 0
        lengthResult.ok = true;
        lengthResult.message = '';
        lengthResult.length_px = fit.curveLength_px;
        lengthResult.length_show = fit.curveLength_show;
        lengthResult.unitLen = fit.curveLengthUnit;
        lengthResult.referencePx = fit.referencePx;
        lengthResult.referenceLength = fit.referenceLength;
        lengthResult.scaleUnit = fit.scaleUnit;
        lengthResult.px_per_unit = fit.px_per_unit;
        lengthResult.usePhysicalScale = fit.usePhysicalScale;
        lengthResult.pointCount = fit.curvePointCount;
    end
end
