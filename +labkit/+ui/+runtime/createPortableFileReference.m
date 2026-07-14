function reference = createPortableFileReference(anchorFile, targetFile)
%CREATEPORTABLEFILEREFERENCE Describe an external file relative to saved state.
%
% App-facing contract:
%   reference = labkit.ui.runtime.createPortableFileReference(anchorFile, targetFile)
%
% Inputs:
%   anchorFile - scalar text path of the project, snapshot, or autosave file.
%   targetFile - scalar text path of an external source file.
%
% Output:
%   reference - schema-1 struct with portable `relativePath`, fallback
%       `originalPath`, and `fileName` fields. The relative path always uses
%       forward slashes and may contain `..` components. Empty inputs produce
%       empty path fields.
%
% The reference stores no file contents and performs no network access.

    anchorFile = string(anchorFile);
    targetFile = string(targetFile);
    [~, fileName, extension] = fileparts(targetFile);
    reference = struct('schemaVersion', 1, 'relativePath', "", ...
        'originalPath', targetFile, 'fileName', fileName + extension);
    if strlength(anchorFile) == 0 || strlength(targetFile) == 0
        return;
    end
    [anchorFolder, ~, ~] = fileparts(anchorFile);
    reference.relativePath = pathRelativeToFolder(anchorFolder, targetFile);
end

function relativePath = pathRelativeToFolder(folder, target)
    folder = replace(string(folder), "\", "/");
    target = replace(string(target), "\", "/");
    if ~isAbsolutePath(target)
        relativePath = target;
        return;
    end
    folderParts = split(strip(folder, "/"), "/");
    targetParts = split(strip(target, "/"), "/");
    commonCount = 0;
    limit = min(numel(folderParts), numel(targetParts));
    while commonCount < limit && ...
            strcmpi(folderParts(commonCount + 1), targetParts(commonCount + 1))
        commonCount = commonCount + 1;
    end
    if commonCount == 0
        relativePath = "";
        return;
    end
    parentParts = repmat("..", numel(folderParts) - commonCount, 1);
    relativePath = join([parentParts; targetParts(commonCount + 1:end)], "/");
end

function tf = isAbsolutePath(pathValue)
    tf = startsWith(pathValue, "/") || startsWith(pathValue, "\\") || ...
        ~isempty(regexp(pathValue, '^[A-Za-z]:/', 'once'));
end
