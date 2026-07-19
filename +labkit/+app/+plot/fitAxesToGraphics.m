function limits = fitAxesToGraphics(axesHandle, varargin)
%FITAXESTOGRAPHICS Fit axes limits to finite plotted X/Y data.
%
% Usage:
%   limits = labkit.app.plot.fitAxesToGraphics(axesHandle)
%   limits = labkit.app.plot.fitAxesToGraphics(axesHandle,graphicsHandles)
%   limits = labkit.app.plot.fitAxesToGraphics(...,Name=Value)
%
% Inputs:
%   axesHandle - Valid scalar MATLAB axes or uiaxes handle.
%   graphicsHandles - Optional graphics contributing XData and YData.
%
% Options:
%   Padding - Nonnegative fractional padding. Default: 0.02.
%
% Outputs:
%   limits - Struct with applied x and y limits.
%
% Description:
%   Ignores nonfinite data and nonpositive logarithmic values. Supplying
%   handles excludes annotations from fitting.
%
% Errors:
%   Throws labkit:app:plot:* for invalid axes or options.
%
% Example:
%   fig = figure(Visible="off");
%   cleanup = onCleanup(@() close(fig));
%   ax = axes(fig);
%   line = plot(ax, [1 2], [3 4]);
%   limits = labkit.app.plot.fitAxesToGraphics(ax, line, Padding=0);
%   assert(isequal(limits.x, [1 2]))
%
% See also labkit.app.plot.clearAxes
limits = labkit.ui.plot.fit(axesHandle, varargin{:});
end
