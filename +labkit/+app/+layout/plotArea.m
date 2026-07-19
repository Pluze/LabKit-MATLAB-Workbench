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
%   AxisIds - Unique MATLAB identifier row. Default: "main".
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
