function [targetFile, matchKind] = resolvePortableFileReference(anchorFile, reference)
%RESOLVEPORTABLEFILEREFERENCE Resolve an external file after saved state moves.
%
% Usage:
%   targetFile = labkit.ui.runtime.resolvePortableFileReference(anchorFile, reference)
%   [targetFile, matchKind] = labkit.ui.runtime.resolvePortableFileReference(...)
%
% Inputs:
%   anchorFile - Path of the loaded project or autosave file.
%   reference - Struct returned by createPortableFileReference. Unknown fields
%       are ignored.
%
% Outputs:
%   targetFile - Canonical path of an existing file, or "" when no candidate
%       can be resolved.
%   matchKind - How the file was found: "relative", "original",
%       "same_folder", or "none".
%
% Description:
%   Candidates are checked in this order: relativePath from the anchor folder,
%   originalPath, then fileName beside the anchor file. Only existing files are
%   accepted; directories are ignored. The function does not display a dialog,
%   read file contents, change app state, or access the network.
%
% Typical Call:
%   [sourceFile, how] = labkit.ui.runtime.resolvePortableFileReference( ...
%       projectFile, project.inputs.sources(1).reference);
%
% See also labkit.ui.runtime.createPortableFileReference

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
