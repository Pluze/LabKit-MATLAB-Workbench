function varargout = gamrywb_CIC_app(varargin)
%GAMRYWB_CIC_APP Compatibility app entry point.
% Delegates to the preserved legacy GUI for the v1.0 behavior-preserving release.

    if nargout > 0
        [varargout{1:nargout}] = gamry_CIC_VT_gui_paperlabels(varargin{:});
    else
        gamry_CIC_VT_gui_paperlabels(varargin{:});
    end
end
