function overlay = makeStrainOverlay(referenceImage, strainMap, mask, roiMask, opts)
%MAKESTRAINOVERLAY Blend a color-mapped strain field over a reference image.
%
% Usage:
%   overlay = dic_postprocess.analysisRun.makeStrainOverlay( ...
%       referenceImage, strainMap, mask, roiMask, opts)
%
% Inputs:
%   referenceImage - Numeric grayscale or RGB image used as the background.
%   strainMap - Two-dimensional numeric strain field on the DIC grid.
%   mask - Logical display mask. It is resized to referenceImage by nearest
%       neighbor before blending.
%   roiMask - Optional logical mask on the strain grid. When nonempty, it
%       determines valid strain samples together with finite strainMap values;
%       otherwise a resized form of mask is used.
%   opts - Scalar overlay option struct described below.
%
% Options:
%   alpha - Strain-color blend fraction; 0 shows the reference and 1 shows the
%       color map inside the overlay mask.
%   colorRange - Two-element [minimum maximum] strain range mapped to the first
%       and last colormap rows. Values outside the range are clipped.
%   colormap - N-by-3 RGB colormap.
%   oversample - Positive strain-grid enlargement factor, rounded to an integer
%       before linear resize. Values below 1 use 1.
%   sigmaSmooth - Gaussian smoothing sigma on the extended strain grid. Values
%       at or below 0 disable smoothing.
%   edgeTrim - Nonnegative number of valid-mask edge pixels removed before
%       interpolation. Default: 1 when the field is absent.
%   brightness - Additive reference-image brightness adjustment.
%   contrast - Multiplicative contrast around normalized intensity 0.5.
%   gamma - Exponent applied after brightness and contrast adjustment.
%   saturation - Multiplier for the HSV saturation channel.
%   rgbGain - Three-element red, green, and blue gain vector.
%
% Outputs:
%   overlay - Double RGB image with the reference height and width. Reference
%       pixels remain unchanged outside the intersection of mask and valid
%       resized strain data.
%
% Description:
%   The reference is normalized and enhanced first. Valid strain values are
%   extended into their ROI, optionally smoothed, linearly resized, clipped to
%   colorRange, and blended only where both masks permit. The function creates
%   image data only and performs no plotting or file output.
%
% Typical Call:
%   opts = struct("alpha", 0.55, "colorRange", [-0.02 0.02], ...
%       "colormap", jet(256), "oversample", 2, "sigmaSmooth", 1, ...
%       "edgeTrim", 1, "brightness", 0, "contrast", 1, ...
%       "gamma", 1, "saturation", 1, "rgbGain", [1 1 1]);
%   overlay = dic_postprocess.analysisRun.makeStrainOverlay( ...
%       referenceImage, strainMap, displayMask, roiMask, opts);
%
% See also dic_postprocess.analysisRun.prepareOutputs,
%   dic_postprocess.analysisRun.summarizeStrain
    orig = dic_postprocess.analysisRun.enhanceReferenceImage(referenceImage, opts);
    [H, W, ~] = size(orig);
    mask = dic_postprocess.analysisRun.resizeNearest(logical(mask), [H W]);
    validMap = dic_postprocess.analysisRun.strainValidMask( ...
        strainMap, roiMask, mask, edgeTrimFromOptions(opts));
    [strainRgb, validStrain] = dic_postprocess.analysisRun.strainToRgb( ...
        strainMap, validMap, [H W], opts);
    overlayMask = mask & validStrain;
    mask3 = repmat(overlayMask, [1 1 3]);
    overlay = orig;
    overlay(mask3) = (1 - opts.alpha) .* orig(mask3) + opts.alpha .* strainRgb(mask3);
end

function edgeTrim = edgeTrimFromOptions(opts)
    edgeTrim = 1;
    if isstruct(opts) && isfield(opts, 'edgeTrim')
        edgeTrim = max(0, round(opts.edgeTrim));
    end
end
