function varargout = gamry_VT_resistance_gui(varargin)
%GAMRY_VT_RESISTANCE_GUI Legacy-directory compatibility shim.

    root = fileparts(fileparts(mfilename('fullpath')));
    paths = strsplit(path, pathsep);
    if ~any(strcmp(paths, root))
        addpath(root);
    end

    if nargout > 0
        [varargout{1:nargout}] = gamry_VT_resistance_gui_legacy(varargin{:});
    else
        gamry_VT_resistance_gui_legacy(varargin{:});
    end
end
