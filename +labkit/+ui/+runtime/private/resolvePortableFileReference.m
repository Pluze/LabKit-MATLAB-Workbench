% Private Runtime V2 loading helper. Expected caller: project source
% resolution. Inputs are the loaded MAT-file path and a portable-reference
% struct. Outputs are the first existing candidate and its match kind; no user
% interaction or reference mutation occurs here.
function [targetFile, matchKind] = resolvePortableFileReference(anchorFile, reference)
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
