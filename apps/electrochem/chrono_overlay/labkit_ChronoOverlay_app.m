function varargout = labkit_ChronoOverlay_app(varargin)
%LABKIT_CHRONOOVERLAY_APP Chrono voltage/current overlay and export app.
% Thin entrypoint that delegates request dispatch, V2 launch, and version title
% handling to the shared runtime.
    [varargout{1:nargout}] = labkit.ui.runtime.launch( ...
        @chrono_overlay.definition, @chrono_overlay.requirements, ...
        @chrono_overlay.version, varargin{:});
end
