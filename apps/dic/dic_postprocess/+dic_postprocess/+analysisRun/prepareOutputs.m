% Expected callers: DIC Postprocess actions and session restoration. Inputs
% are loaded source data and display parameters. Outputs are the summary table
% plus EXX/EYY RGB overlays. Side effects are none.
function [summaryTable, overlayExx, overlayEyy] = prepareOutputs(inputs, parameters)
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
