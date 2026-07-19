function clearAxes(axesHandle, varargin)
%CLEARAXES Prepare axes for one complete App-owned redraw.
%
% Usage:
%   labkit.app.plot.clearAxes(axesHandle)
%   labkit.app.plot.clearAxes(axesHandle, Name=Value)
%
% Inputs:
%   axesHandle - Valid scalar MATLAB axes or uiaxes handle.
%
% Options:
%   ResetScale - Restore linear X/Y scales and automatic ticks. Default:
%       false.
%   ClearLegend - Turn the legend off. Default: true.
%
% Outputs:
%   None.
%
% Description:
%   Deletes plotted children, releases hold, clears cached home-view state,
%   and restores automatic limits. Use only at a complete redraw boundary;
%   overlay edits should preserve the current viewport.
%
% Errors:
%   Throws labkit:app:plot:* for invalid axes or options.
%
% Example:
%   fig = figure(Visible="off");
%   cleanup = onCleanup(@() close(fig));
%   ax = axes(fig);
%   plot(ax, 1:3);
%   labkit.app.plot.clearAxes(ax);
%   assert(isempty(ax.Children))
%
% See also labkit.app.plot.showMessage,
%   labkit.app.plot.fitAxesToGraphics
labkit.ui.plot.clear(axesHandle, varargin{:});
end
