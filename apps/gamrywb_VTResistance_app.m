function varargout = gamrywb_VTResistance_app(varargin)
%GAMRYWB_VTRESISTANCE_APP Compatibility app entry point.
% Temporarily delegates to the preserved legacy reference until package-backed app internals replace it.

    root = fileparts(fileparts(mfilename('fullpath')));
    legacyDir = fullfile(root, 'legacy');
    addedLegacyPath = ~any(strcmp(strsplit(path, pathsep), legacyDir));
    if addedLegacyPath
        addpath(legacyDir, '-end');
        cleanupLegacyPath = onCleanup(@() rmpath(legacyDir)); %#ok<NASGU>
    end

    if nargout > 0
        [varargout{1:nargout}] = gamry_VT_resistance_gui_legacy(varargin{:});
    else
        gamry_VT_resistance_gui_legacy(varargin{:});
    end
end
