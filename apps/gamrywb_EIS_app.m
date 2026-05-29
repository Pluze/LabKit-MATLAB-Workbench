function varargout = gamrywb_EIS_app(varargin)
%GAMRYWB_EIS_APP Thin app entry point for EIS overlay/export analysis.

    if nargout > 0
        [varargout{1:nargout}] = gamry_EIS_multiDTA_plot_gui(varargin{:});
    else
        gamry_EIS_multiDTA_plot_gui(varargin{:});
    end
end
