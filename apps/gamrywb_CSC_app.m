function varargout = gamrywb_CSC_app(varargin)
%GAMRYWB_CSC_APP Thin app entry point for CV/CT charge and CSC analysis.

    if nargout > 0
        [varargout{1:nargout}] = gamry_CV_CSC_dta_gui(varargin{:});
    else
        gamry_CV_CSC_dta_gui(varargin{:});
    end
end
