function folder = defaultOutputFolder(sourcePaths, subfolderName, fallbackFolder)
%DEFAULTOUTPUTFOLDER Return a source-adjacent app output folder.
%
% App-facing contract:
%   folder = labkit.ui.runtime.defaultOutputFolder(sourcePaths, subfolderName)
%   folder = labkit.ui.runtime.defaultOutputFolder(..., fallbackFolder)
%
% Inputs:
%   sourcePaths - file or folder path, or a string/cell array of paths. When
%       multiple paths are provided, the first path decides the base folder.
%   subfolderName - output subfolder name created under the source folder.
%   fallbackFolder - optional folder used when no source folder can be
%       resolved.
%
% Outputs:
%   folder - existing output folder path. The helper creates the requested
%       subfolder when possible and otherwise falls back to a safe LabKit
%       output dialog folder.

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
        baseFolder = string(labkit.ui.runtime.defaultDialogFolder("output", fallbackFolder));
    end

    target = string(fullfile(char(baseFolder), char(safeSubfolderName(subfolderName))));
    if ensureFolder(target)
        folder = char(target);
        return;
    end

    folder = labkit.ui.runtime.defaultDialogFolder("output", fallbackFolder);
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
