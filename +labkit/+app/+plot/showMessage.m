function textHandle = showMessage(axesHandle, message, varargin)
%SHOWMESSAGE Replace plot content with a centered noninteractive message.
%
% Usage:
%   textHandle = labkit.app.plot.showMessage(axesHandle,message,Name=Value)
%
% Inputs:
%   axesHandle - Valid scalar MATLAB axes or uiaxes handle.
%   message - Scalar user-visible text.
%
% Options:
%   Title - Axes title. Default: "".
%   Color - MATLAB text color. Default: [0.30 0.30 0.30].
%
% Outputs:
%   textHandle - MATLAB text object containing the message.
%
% Description:
%   Performs a complete clear, sets unit limits, hides ticks, and creates
%   display-only text for empty, loading, or unavailable plot states.
%
% Errors:
%   Throws labkit:app:plot:* for invalid axes, text, or options.
%
% Example:
%   fig = figure(Visible="off");
%   cleanup = onCleanup(@() close(fig));
%   ax = axes(fig);
%   label = labkit.app.plot.showMessage(ax, "No data");
%   assert(string(label.String) == "No data")
%
% See also labkit.app.plot.clearAxes
textHandle = labkit.ui.plot.message(axesHandle, message, varargin{:});
end
