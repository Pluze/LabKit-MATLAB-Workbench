function varargout = labkit_ChronoOverlay_app(varargin)
%LABKIT_CHRONOOVERLAY_APP Chrono voltage/current overlay and export app.
% Thin entrypoint delegates product metadata and launch behavior to one definition.
    [varargout{1:nargout}] = ...
        chrono_overlay.definition().launch(varargin{:});
end
