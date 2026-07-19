function calibration = scaleCalibration( ...
        referencePixels, referenceLength, unitName, options)
%SCALECALIBRATION Build a serializable pixels-per-unit calibration.
%
% Usage:
%   calibration = labkit.app.interaction.scaleCalibration( ...
%       referencePixels,referenceLength,unitName)
%   calibration = labkit.app.interaction.scaleCalibration(...,options)
%
% Inputs:
%   referencePixels - Positive measured distance in pixels, or empty.
%   referenceLength - Nonnegative physical reference length.
%   unitName - Unit label.
%   options - Optional scalar struct with units, defaultUnit, and
%       referenceLine fields. Default: struct().
%
% Outputs:
%   calibration - Serializable struct containing normalized reference values,
%       pixelsPerUnit, isCalibrated, unit, and referenceLine.
%
% Failure Behavior:
%   Missing measurement values produce an uncalibrated result. Incompatible
%   option values propagate conversion errors.
%
% Example:
%   calibration = labkit.app.interaction.scaleCalibration(80,20,"mm");
%   assert(calibration.isCalibrated)
%
% See also labkit.app.interaction.scaleBarGeometry,
%   labkit.app.interaction.scaleReference
if nargin < 4
    options = struct();
end
calibration = labkit.ui.interaction.scaleBarCalibration( ...
    referencePixels, referenceLength, unitName, options);
end
