function varargout = gamry_CIC_VT_gui_paperlabels(varargin)
%GAMRY_CIC_VT_GUI_PAPERLABELS Compatibility entry point for the legacy GUI.

    root = fileparts(mfilename('fullpath'));
    legacyDir = fullfile(root, 'legacy');
    paths = strsplit(path, pathsep);
    if ~any(strcmp(paths, legacyDir))
        addpath(legacyDir, '-end');
        cleanupLegacyPath = onCleanup(@() rmpath(legacyDir)); %#ok<NASGU>
    end

    if nargout > 0
        [varargout{1:nargout}] = gamry_CIC_VT_gui_paperlabels_legacy(varargin{:});
    else
        gamry_CIC_VT_gui_paperlabels_legacy(varargin{:});
    end
end
