function reference = createPortableFileReference(anchorFile, targetFile)
%CREATEPORTABLEFILEREFERENCE Describe an external file relative to saved state.
%
% Usage:
%   reference = labkit.ui.runtime.createPortableFileReference(anchorFile, targetFile)
%
% Inputs:
%   anchorFile - Path of the project or autosave file that will store the
%       reference. The file does not need to exist.
%   targetFile - Path of the external source file. The file does not need to
%       exist.
%
% Outputs:
%   reference - Scalar struct with schemaVersion, relativePath, originalPath,
%       and fileName fields.
%
% Reference Fields:
%   schemaVersion - Reference schema number. The current value is 1.
%   relativePath - targetFile expressed relative to the folder containing
%       anchorFile, using forward slashes. It is "" when no relative path can
%       be formed.
%   originalPath - targetFile exactly as supplied by the caller.
%   fileName - Final file name and extension from targetFile.
%
% Description:
%   The returned reference gives the loader three ways to find a moved source:
%   its path relative to anchorFile, its original path, and its file name beside
%   the saved project. relativePath uses forward slashes and may contain "..".
%   A relative targetFile is stored unchanged. If two absolute paths have no
%   common root, relativePath is empty and the other fallbacks remain usable.
%   This function only records path text; it does not open either file.
%
% Example:
%   ref = labkit.ui.runtime.createPortableFileReference( ...
%       fullfile("study", "project.mat"), fullfile("images", "frame01.tif"));
%   assert(ref.relativePath == "images/frame01.tif")
%
% See also labkit.ui.runtime.resolvePortableFileReference

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
