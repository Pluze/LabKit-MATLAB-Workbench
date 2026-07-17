function [summaryTable, overlayExx, overlayEyy] = prepareOutputs(inputs, parameters)
%PREPAREOUTPUTS Build DIC strain summaries and both display overlays.
%
% Usage:
%   [summaryTable, overlayExx, overlayEyy] = ...
%       dic_postprocess.analysisRun.prepareOutputs(inputs, parameters)
%
% Inputs:
%   inputs - Scalar source struct with referenceImage, maskImage, and strain.
%       strain must contain exx, eyy, and roiMask arrays on a common DIC grid.
%   parameters - Scalar display struct described below.
%
% Parameters:
%   alpha - Overlay blend fraction.
%   colorMin - Lower shared EXX/EYY strain color limit.
%   colorMax - Upper shared EXX/EYY strain color limit.
%   oversample - Strain-grid interpolation enlargement factor.
%   smoothSigma - Gaussian smoothing sigma.
%   edgeTrim - Valid strain edge pixels removed before interpolation.
%   brightness - Additive normalized reference brightness adjustment.
%   contrast - Reference contrast multiplier around 0.5.
%   gamma - Reference-image intensity exponent.
%   saturation - Reference HSV saturation multiplier.
%   redGain - Reference red-channel multiplier.
%   greenGain - Reference green-channel multiplier.
%   blueGain - Reference blue-channel multiplier.
%
% Outputs:
%   summaryTable - Five-row table of Mean, Std, Median, Min, and Max with EXX
%       and EYY columns.
%   overlayExx - Double RGB EXX overlay at referenceImage size.
%   overlayEyy - Double RGB EYY overlay at referenceImage size.
%
% Description:
%   prepareOutputs is the GUI-free composition used by the app. It converts the
%   mask image to a logical display mask, uses a fixed 256-color jet map for
%   both components, renders EXX and EYY with identical display parameters, and
%   summarizes finite strain samples inside roiMask when supplied.
%
% Failure Behavior:
%   Missing input/parameter fields, incompatible EXX/EYY/mask geometry, or
%   invalid display values propagate the originating field-access, overlay, or
%   summary error. The function does not catch partial-output failures.
%
% Typical Call:
%   [summary, exxImage, eyyImage] = ...
%       dic_postprocess.analysisRun.prepareOutputs(inputs, parameters);
%
% See also dic_postprocess.analysisRun.makeStrainOverlay,
%   dic_postprocess.analysisRun.summarizeStrain
    options = overlayOptions(parameters);
    overlayMask = dic_postprocess.analysisRun.imageMask(inputs.maskImage, ...
        dic_postprocess.analysisRun.imageHeightWidth(inputs.referenceImage));
    overlayExx = dic_postprocess.analysisRun.makeStrainOverlay( ...
        inputs.referenceImage, inputs.strain.exx, overlayMask, ...
        inputs.strain.roiMask, options);
    overlayEyy = dic_postprocess.analysisRun.makeStrainOverlay( ...
        inputs.referenceImage, inputs.strain.eyy, overlayMask, ...
        inputs.strain.roiMask, options);
    summaryMask = dic_postprocess.analysisRun.summaryMaskForStrain(inputs.strain);
    summaryTable = dic_postprocess.analysisRun.summarizeStrain( ...
        inputs.strain, summaryMask);
end

function options = overlayOptions(parameters)
    options = struct();
    options.alpha = parameters.alpha;
    options.colorRange = [parameters.colorMin parameters.colorMax];
    options.oversample = max(1, round(parameters.oversample));
    options.sigmaSmooth = parameters.smoothSigma;
    options.edgeTrim = max(0, round(parameters.edgeTrim));
    options.colormap = jet(256);
    options.brightness = parameters.brightness;
    options.contrast = parameters.contrast;
    options.gamma = parameters.gamma;
    options.saturation = parameters.saturation;
    options.rgbGain = [parameters.redGain parameters.greenGain ...
        parameters.blueGain];
end
