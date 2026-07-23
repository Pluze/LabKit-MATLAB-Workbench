function root = setup()
%SETUP Configure the MATLAB path required by LabKit test specifications.
%   ROOT = labkittest.setup adds the repository root, every public App entry
%   folder and tests to the current MATLAB session. It returns
%   the repository root. The function is idempotent and does not add legacy
%   runner folders.
%
%   Test specifications normally do not call this function themselves:
%   labkittest.run invokes it before executing a compiled plan. It remains
%   available for focused specification development in a clean MATLAB session.

    packageFolder = fileparts(mfilename("fullpath"));
    root = fileparts(fileparts(packageFolder));
    folders = [string(root), ...
        string(fullfile(root, "apps")), ...
        string(fullfile(root, "tests")), ...
        publicAppFolders(root)];
    current = string(strsplit(path, pathsep));
    folders = folders(arrayfun(@(folder) exist(folder, "dir") == 7, folders));
    folders = folders(~ismember(folders, current));
    if ~isempty(folders)
        addpath(char(strjoin(folders, pathsep)), "-end");
    end
end

function folders = publicAppFolders(root)
    entries = dir(fullfile(root, "apps", "**", "labkit_*_app.m"));
    folders = unique(string({entries.folder}), "stable");
end
