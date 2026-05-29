function varargout = gamrywb_VTResistance_app(varargin)
%GAMRYWB_VTRESISTANCE_APP Compatibility app entry point.
% Delegates to the preserved legacy GUI for the v1.0 behavior-preserving release.

    if nargout > 0
        [varargout{1:nargout}] = gamry_VT_resistance_gui(varargin{:});
    else
        gamry_VT_resistance_gui(varargin{:});
    end
end
