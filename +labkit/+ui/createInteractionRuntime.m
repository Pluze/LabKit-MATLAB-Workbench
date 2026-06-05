function runtime = createInteractionRuntime(ax, opts)
%CREATEINTERACTIONRUNTIME Create a managed interaction runtime for axes tools.
%
% Usage:
%   runtime = labkit.ui.createInteractionRuntime(ax, ...
%       struct('figure', fig, 'defaultScrollFcn', @onPreviewScroll));
%   session = runtime.createSession(struct( ...
%       'name', 'toolName', ...
%       'onPointerDown', @onPointerDown, ...
%       'onScroll', @onScroll, ...
%       'installScrollWheel', true));
%
% Inputs:
%   ax - UI axes used by an image or axes interaction tool.
%   opts - optional struct.
%
% Options:
%   figure - owning figure, default ancestor(ax, 'figure').
%   defaultScrollFcn - default scroll callback restored when no session owns
%       scrolling, default [].
%   onInteractionChanged - callback(active, name), default [].
%   onTrace - callback(message), default []. Receives verbose lifecycle trace.
%
% Output:
%   runtime - struct with axes, figure, setFigure, setDefaultScrollFcn,
%       setTraceCallback, installDefaultCallbacks, createSession,
%       isInteractionActive, and delete.
%
% Runtime sessions own pointer, drag, scroll, hit-test, and callback restore
% mechanics. Apps and composed tools should use sessions instead of mutating
% figure or axes pointer callbacks directly.

    if nargin < 2
        opts = struct();
    end
    runtime = labkit.ui.createImageAxesRuntime(ax, opts);
end
