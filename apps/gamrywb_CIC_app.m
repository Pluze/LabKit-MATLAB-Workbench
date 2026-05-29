function varargout = gamrywb_CIC_app(varargin)
%GAMRYWB_CIC_APP Thin app entry point for CIC / voltage-transient analysis.

    if nargout > 0
        [varargout{1:nargout}] = gamry_CIC_VT_gui_paperlabels(varargin{:});
    else
        gamry_CIC_VT_gui_paperlabels(varargin{:});
    end
end
