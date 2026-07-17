function folder = defaultOutputFolder(sourcePaths, subfolderName, fallbackFolder)
%DEFAULTOUTPUTFOLDER Return a source-adjacent app output folder.
%
% Usage:
%   folder = labkit.ui.runtime.defaultOutputFolder(sourcePaths, subfolderName)
%   folder = labkit.ui.runtime.defaultOutputFolder(sourcePaths, subfolderName, fallbackFolder)
%
% Inputs:
%   sourcePaths - File path, folder path, string array, or cell array of paths.
%       The first nonempty path selects the base folder. The default is empty.
%   subfolderName - Name of the output folder to create. Characters that are
%       illegal in common file systems are replaced with underscores. The
%       default is "labkit_output".
%   fallbackFolder - Existing folder to use when sourcePaths does not identify
%       an existing source location. The default is LabKit's remembered output
%       location or the current user's home folder.
%
% Outputs:
%   folder - Character vector naming an existing output folder.
%
% Description:
%   When the first path is a file, the new subfolder is created beside that
%   file. When it is a folder, the subfolder is created inside it. If the source
%   cannot be resolved or the new folder cannot be created, the function
%   returns a safe existing fallback folder instead of failing because the
%   requested output folder could not be created.
%
% Failure Behavior:
%   Missing source locations, unsafe names, and mkdir failures fall back to an
%   existing remembered output folder or user home directory. Input values
%   must be convertible to text; incompatible MATLAB containers may raise the
%   originating string conversion error before fallback selection.
%
% Typical Call:
%   outputFolder = labkit.ui.runtime.defaultOutputFolder( ...
%       importedFiles, "Processed Results", pwd);
%
% See also labkit.ui.runtime.sourcePaths,
%   labkit.ui.runtime.saveState

    if nargin < 1
        sourcePaths = strings(0, 1);
    end
    if nargin < 2 || strlength(strtrim(string(subfolderName))) == 0
        subfolderName = "labkit_output";
    end
    if nargin < 3
        fallbackFolder = "";
    end

    baseFolder = sourceBaseFolder(sourcePaths);
    if strlength(baseFolder) == 0
        baseFolder = string(defaultDialogFolder("output", fallbackFolder));
    end

    target = string(fullfile(char(baseFolder), char(safeSubfolderName(subfolderName))));
    if ensureFolder(target)
        folder = char(target);
        return;
    end

    folder = defaultDialogFolder("output", fallbackFolder);
end

function folder = sourceBaseFolder(sourcePaths)
    folder = "";
    if isempty(sourcePaths)
        return;
    end

    paths = string(sourcePaths);
    paths = paths(strlength(strtrim(paths)) > 0);
    if isempty(paths)
        return;
    end

    firstPath = strtrim(paths(1));
    if exist(char(firstPath), 'dir') == 7
        folder = firstPath;
        return;
    end

    [parentFolder, ~, ~] = fileparts(char(firstPath));
    if ~isempty(parentFolder) && exist(parentFolder, 'dir') == 7
        folder = string(parentFolder);
    end
end

function name = safeSubfolderName(value)
    name = strtrim(string(value));
    if isempty(name) || strlength(name(1)) == 0
        name = "labkit_output";
    else
        name = name(1);
    end
    invalid = ["<", ">", ":", """", "/", "\", "|", "?", "*"];
    for k = 1:numel(invalid)
        name = replace(name, invalid(k), "_");
    end
end

function ok = ensureFolder(folder)
    ok = exist(char(folder), 'dir') == 7;
    if ok
        return;
    end
    try
        [ok, ~, ~] = mkdir(char(folder));
    catch
        ok = false;
    end
end
