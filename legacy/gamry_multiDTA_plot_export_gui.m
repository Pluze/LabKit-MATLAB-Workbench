function varargout = gamry_multiDTA_plot_export_gui(varargin)
%GAMRY_MULTIDTA_PLOT_EXPORT_GUI Legacy-directory compatibility shim.

    root = fileparts(fileparts(mfilename('fullpath')));
    paths = strsplit(path, pathsep);
    if ~any(strcmp(paths, root))
        addpath(root);
    end

    if nargout > 0
        [varargout{1:nargout}] = gamry_multiDTA_plot_export_gui_legacy(varargin{:});
    else
        gamry_multiDTA_plot_export_gui_legacy(varargin{:});
    end
end
