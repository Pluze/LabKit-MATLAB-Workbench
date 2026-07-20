function node = plotArea(id, renderer, varargin)
%PLOTAREA Add one or more axes rendered by an App-owned renderer.
%
% Usage:
%   node = labkit.app.layout.plotArea(id, renderer, Name=Value)
%
% Description:
%   Declares axes and their one App-owned renderer. The renderer is declared
%   here once; a view snapshot supplies only its current model.
%
% Inputs:
%   id - Unique MATLAB identifier for the layout target.
%   renderer - Scalar function handle renderer(axesById,model) with no
%       output. axesById is always a scalar struct with one graphics axes
%       field per declared AxisIds value, including single-axis plots.
%
% Options:
%   Title - Reader-facing panel title or blank. Default: blank.
%   Layout - Axes arrangement: "single", "pair", or "stack". Default:
%       "single" for one axis and "stack" for multiple axes.
%   AxisIds - Unique MATLAB identifier row. Default: "main".
%   AxisTitles - One title per axis. Default: axis IDs.
%   XLabels - One x-axis label per axis. Default: blank.
%   YLabels - One y-axis label per axis. Default: blank.
%   ColumnWidths - One positive pixel, "fit", or "1x" value per axis for
%       pair layout. Default: equal flexible widths.
%   RowHeights - One positive pixel, "fit", or "1x" value per axis for
%       stack layout. Default: equal flexible heights.
%   ScrollZoomAxes - One "xy", "x", or "y" value per axis. Default: "xy".
%   ViewModes - App-owned mode labels. Default: strings(1,0).
%   OnValueChanged - Scalar callback
%       state = callback(state,value,context). Default: [].
%   Interactions - Row cell array returned by named
%       labkit.app.interaction.* declarations. Default: {}.
%
% Outputs:
%   node - Immutable internal layout node accepted by workspace.
%
% Errors:
%   Throws labkit:app:contract:* for invalid IDs, options, or handlers.
%
% Typical Call:
%   node = labkit.app.layout.plotArea("preview", @drawTrace, ...
%       AxisIds="trace");
%
% See also labkit.app.view.Snapshot, labkit.app.layout.workspace,
%   labkit.app.interaction.anchorPath
node = labkit.app.internal.LayoutNode.plotArea(id, renderer, varargin{:});
end
