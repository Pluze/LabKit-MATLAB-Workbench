function varargout = gamrywb_CSC_app(varargin)
%GAMRYWB_CSC_APP Compatibility app entry point.
% Delegates to the preserved legacy GUI for the v1.0 behavior-preserving release.

    if nargout > 0
        [varargout{1:nargout}] = gamry_CV_CSC_dta_gui(varargin{:});
    else
        gamry_CV_CSC_dta_gui(varargin{:});
    end
end
