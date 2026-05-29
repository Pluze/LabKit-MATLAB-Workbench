function varargout = gamry_CV_CSC_dta_gui(varargin)
%GAMRY_CV_CSC_DTA_GUI Compatibility entry point for the legacy GUI.

    root = fileparts(mfilename('fullpath'));
    legacyDir = fullfile(root, 'legacy');
    paths = strsplit(path, pathsep);
    if ~any(strcmp(paths, legacyDir))
        addpath(legacyDir, '-end');
        cleanupLegacyPath = onCleanup(@() rmpath(legacyDir)); %#ok<NASGU>
    end

    if nargout > 0
        [varargout{1:nargout}] = gamry_CV_CSC_dta_gui_legacy(varargin{:});
    else
        gamry_CV_CSC_dta_gui_legacy(varargin{:});
    end
end
