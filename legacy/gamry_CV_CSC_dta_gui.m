function varargout = gamry_CV_CSC_dta_gui(varargin)
%GAMRY_CV_CSC_DTA_GUI Legacy-directory compatibility shim.

    root = fileparts(fileparts(mfilename('fullpath')));
    paths = strsplit(path, pathsep);
    if ~any(strcmp(paths, root))
        addpath(root);
    end

    if nargout > 0
        [varargout{1:nargout}] = gamry_CV_CSC_dta_gui_legacy(varargin{:});
    else
        gamry_CV_CSC_dta_gui_legacy(varargin{:});
    end
end
