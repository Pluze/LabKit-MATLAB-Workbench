function varargout = gamrywb_VTResistance_app(varargin)
%GAMRYWB_VTRESISTANCE_APP Thin app entry point for VT resistance analysis.

    if nargout > 0
        [varargout{1:nargout}] = gamry_VT_resistance_gui(varargin{:});
    else
        gamry_VT_resistance_gui(varargin{:});
    end
end
