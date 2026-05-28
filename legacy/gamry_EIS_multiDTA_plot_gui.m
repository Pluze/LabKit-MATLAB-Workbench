function varargout = gamry_EIS_multiDTA_plot_gui(varargin)
%GAMRY_EIS_MULTIDTA_PLOT_GUI Legacy-directory compatibility shim.

    root = fileparts(fileparts(mfilename('fullpath')));
    paths = strsplit(path, pathsep);
    if ~any(strcmp(paths, root))
        addpath(root);
    end

    if nargout > 0
        [varargout{1:nargout}] = gamry_EIS_multiDTA_plot_gui_legacy(varargin{:});
    else
        gamry_EIS_multiDTA_plot_gui_legacy(varargin{:});
    end
end
