function varargout = gamrywb_EIS_app(varargin)
%GAMRYWB_EIS_APP Compatibility app entry point.
% Delegates to the preserved legacy GUI for the v1.0 behavior-preserving release.

    if nargout > 0
        [varargout{1:nargout}] = gamry_EIS_multiDTA_plot_gui(varargin{:});
    else
        gamry_EIS_multiDTA_plot_gui(varargin{:});
    end
end
