function varargout = labkit_ChronoOverlay_app(varargin)
%LABKIT_CHRONOOVERLAY_APP Chrono voltage/current overlay and export app.
% Thin entrypoint delegates product metadata and launch behavior to one definition.
    app = chrono_overlay.definition();
    [varargout{1:nargout}] = app.launch(varargin{:});
end
