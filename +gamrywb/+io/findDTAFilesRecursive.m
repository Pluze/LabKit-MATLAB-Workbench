function filepaths = findDTAFilesRecursive(rootDir)
%FINDDTAFILESRECURSIVE Recursively collect .DTA/.dta files.

    entries = dir(rootDir);
    filepaths = {};

    for i = 1:numel(entries)
        name = entries(i).name;
        if strcmp(name, '.') || strcmp(name, '..')
            continue;
        end

        fullpath = fullfile(entries(i).folder, name);
        if entries(i).isdir
            subpaths = gamrywb.io.findDTAFilesRecursive(fullpath);
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
