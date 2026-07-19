function [applied, frame] = fitCanvasToSource( ...
        axesHandle, sourceWidth, sourceHeight, varargin)
%FITCANVASTOSOURCE Fit preview axes to a fixed-aspect source canvas.
%
% Usage:
%   [applied,frame] = labkit.app.plot.fitCanvasToSource( ...
%       axesHandle,sourceWidth,sourceHeight,Name=Value)
%
% Inputs:
%   axesHandle - UI axes hosted by a preview grid.
%   sourceWidth - Positive finite source width in pixels.
%   sourceHeight - Positive finite source height in pixels.
%
% Options:
%   margin - Preferred empty pixel margin. Default: 24.
%   maxScale - Largest display/source ratio. Default: 1.
%
% Outputs:
%   applied - true when layout was updated.
%   frame - Applied source/display geometry, or empty struct.
%
% Failure Behavior:
%   Unsuitable axes, host, dimensions, or available space return false.
%   Malformed options throw labkit:app:plot:*.
%
% Typical Call:
%   [ok,frame] = labkit.app.plot.fitCanvasToSource(ax,720,540);
%
% See also labkit.app.layout.plotArea
[applied, frame] = labkit.ui.plot.fitCanvas( ...
    axesHandle, sourceWidth, sourceHeight, varargin{:});
end
