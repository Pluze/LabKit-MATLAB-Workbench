function geometry = scaleBarGeometry( ...
        imageSize, calibration, barLength, position, colorName)
%SCALEBARGEOMETRY Compute serializable image scale-bar overlay geometry.
%
% Usage:
%   geometry = labkit.app.interaction.scaleBarGeometry( ...
%       imageSize,calibration,barLength,position,colorName)
%
% Inputs:
%   imageSize - Image dimensions beginning with height and width.
%   calibration - Value returned by interaction.scaleCalibration.
%   barLength - Positive physical length in calibration units.
%   position - Text containing top/bottom and left/center/right.
%   colorName - "White" for white; other values select black.
%
% Outputs:
%   geometry - Serializable line, label, color, and placement struct.
%
% Errors:
%   Throws labkit:app:interaction:* when dimensions, calibration, or requested
%   scale-bar length are invalid.
%
% Example:
%   calibration = labkit.app.interaction.scaleCalibration(80,20,"mm");
%   geometry = labkit.app.interaction.scaleBarGeometry( ...
%       [600 800],calibration,10,"Bottom right","White");
%   assert(abs(diff(geometry.line(:,1))) == 40)
%
% See also labkit.app.interaction.scaleCalibration
geometry = labkit.ui.interaction.scaleBarGeometry( ...
    imageSize, calibration, barLength, position, colorName);
end
