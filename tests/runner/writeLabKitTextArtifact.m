function writeLabKitTextArtifact(filepath, lines)
%WRITELABKITTEXTARTIFACT Write a UTF-8 text artifact.
%
% Expected caller: test runners and GUI artifact helpers. Inputs are an
% absolute or repo-local file path and a string, char, or cellstr line list.
% Side effects: creates the parent folder and overwrites the target file.

    ensureParent(filepath);
    text = normalizeText(lines);
    fid = fopen(filepath, "w", "n", "UTF-8");
    assert(fid > 0, "Unable to open artifact for writing: %s", filepath);
    cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, "%s", text);
end

function text = normalizeText(lines)
    if iscell(lines)
        lines = string(lines);
    end
    if isstring(lines)
        text = strjoin(lines(:), newline);
    else
        text = char(lines);
    end
    text = string(text);
    if ~endsWith(string(text), newline)
        text = text + newline;
    end
    text = char(text);
end

function ensureParent(filepath)
    parent = fileparts(filepath);
    if ~isempty(parent) && exist(parent, "dir") ~= 7
        mkdir(parent);
    end
end
