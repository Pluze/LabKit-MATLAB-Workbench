function filepaths = findDTAFilesRecursive(rootDir)
%FINDDTAFILESRECURSIVE Recursively collect .DTA/.dta files below a folder.
%
% Called by:
%   labkit.dta.findFiles
%
% Inputs:
%   rootDir - existing folder path.
%
% Output:
%   filepaths - cell row of absolute or dir-returned full paths in traversal
%               order. Files are accepted by case-insensitive .dta extension.
%
% Notes:
%   The public facade is responsible for folder validation and sorting policy
%   changes; this helper only walks the tree.

    entries = dir(rootDir);
    filepaths = {};

    for i = 1:numel(entries)
        name = entries(i).name;
        if strcmp(name, '.') || strcmp(name, '..')
            continue;
        end

        fullpath = fullfile(entries(i).folder, name);
        if entries(i).isdir
            subpaths = findDTAFilesRecursive(fullpath);
            if ~isempty(subpaths)
                filepaths = [filepaths, subpaths]; %#ok<AGROW>
            end
        else
            [~, ~, ext] = fileparts(name);
            if strcmpi(ext, '.dta')
                filepaths{end+1} = fullpath; %#ok<AGROW>
            end
        end
    end
end
