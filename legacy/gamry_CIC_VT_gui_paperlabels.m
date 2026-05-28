function varargout = gamry_CIC_VT_gui_paperlabels(varargin)
%GAMRY_CIC_VT_GUI_PAPERLABELS Legacy-directory compatibility shim.

    root = fileparts(fileparts(mfilename('fullpath')));
    paths = strsplit(path, pathsep);
    if ~any(strcmp(paths, root))
        addpath(root);
    end

    if nargout > 0
        [varargout{1:nargout}] = gamry_CIC_VT_gui_paperlabels_legacy(varargin{:});
    else
        gamry_CIC_VT_gui_paperlabels_legacy(varargin{:});
    end
end
