function varargout = gamry_EIS_multiDTA_plot_gui(varargin)
%GAMRY_EIS_MULTIDTA_PLOT_GUI Compatibility entry point for the legacy GUI.

    root = fileparts(mfilename('fullpath'));
    legacyDir = fullfile(root, 'legacy');
    paths = strsplit(path, pathsep);
    if ~any(strcmp(paths, legacyDir))
        addpath(legacyDir, '-end');
        cleanupLegacyPath = onCleanup(@() rmpath(legacyDir)); %#ok<NASGU>
    end

    if nargout > 0
        [varargout{1:nargout}] = gamry_EIS_multiDTA_plot_gui_legacy(varargin{:});
    else
        gamry_EIS_multiDTA_plot_gui_legacy(varargin{:});
    end
end
