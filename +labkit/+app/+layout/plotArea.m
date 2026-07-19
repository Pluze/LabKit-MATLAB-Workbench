function node = plotArea(id, varargin)
%PLOTAREA Add one or more axes rendered by an App-owned renderer.
%
% Usage:
%   node = labkit.app.layout.plotArea(id, Name=Value)
%
% Description:
%   Declares axes and the renderer IDs permitted to update them.
%
% Inputs:
%   id - Unique MATLAB identifier for the layout target.
%
% Options:
%   AxisIds - Unique MATLAB identifier row. Default: "main".
%   Renderers - Unique declared renderer-ID row. Default: strings(1,0).
%   ViewModes - App-owned mode labels. Default: strings(1,0).
%   ValueChanged - StateHandler with Event="valueChange". Default: [].
%
% Outputs:
%   node - Immutable internal layout node accepted by workspace.
%
% Errors:
%   Throws labkit:app:contract:* for invalid IDs, options, or handlers.
%
% Typical Call:
%   node = labkit.app.layout.plotArea("preview", Renderers="trace");
%
% See also labkit.app.view.Snapshot, labkit.app.layout.workspace
node = labkit.app.internal.LayoutNode.plotArea(id, varargin{:});
end
