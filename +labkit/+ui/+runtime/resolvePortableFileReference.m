function [targetFile, matchKind] = resolvePortableFileReference(anchorFile, reference)
%RESOLVEPORTABLEFILEREFERENCE Resolve an external file after saved state moves.
%
% App-facing contract:
%   targetFile = labkit.ui.runtime.resolvePortableFileReference(anchorFile, reference)
%   [targetFile, matchKind] = labkit.ui.runtime.resolvePortableFileReference(...)
%
% Inputs:
%   anchorFile - scalar text path of the loaded project, snapshot, or autosave.
%   reference - struct created by `createPortableFileReference`. Additive
%       unknown fields are ignored for forward compatibility.
%
% Outputs:
%   targetFile - canonical existing file path, or empty text when unresolved.
%   matchKind - `relative`, `original`, `same_folder`, or `none`.
%
% Resolution order is relative path, original path, then the saved filename
% beside the anchor file. The function does not prompt, inspect file contents,
% mutate state, or access the network.

    anchorFile = string(anchorFile);
    [anchorFolder, ~, ~] = fileparts(anchorFile);
    candidates = strings(0, 1);
    kinds = strings(0, 1);
    if isfield(reference, 'relativePath') && strlength(reference.relativePath) > 0
        parts = cellstr(split(replace(string(reference.relativePath), "\", "/"), "/"));
        candidates(end + 1) = fullfile(anchorFolder, parts{:});
        kinds(end + 1) = "relative";
    end
    if isfield(reference, 'originalPath') && strlength(reference.originalPath) > 0
        candidates(end + 1) = string(reference.originalPath);
        kinds(end + 1) = "original";
    end
    if isfield(reference, 'fileName') && strlength(reference.fileName) > 0
        candidates(end + 1) = fullfile(anchorFolder, string(reference.fileName));
        kinds(end + 1) = "same_folder";
    end
    targetFile = "";
    matchKind = "none";
    for index = 1:numel(candidates)
        [exists, attributes] = fileattrib(char(candidates(index)));
        if exists && ~attributes.directory
            targetFile = string(attributes.Name);
            matchKind = kinds(index);
            return;
        end
    end
end
