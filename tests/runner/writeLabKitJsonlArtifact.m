function writeLabKitJsonlArtifact(filepath, records)
%WRITELABKITJSONLARTIFACT Write struct records as JSON Lines.
%
% Expected caller: structured trace and machine-readable GUI artifact code.
% Inputs: a file path and a struct array or cell array of JSON-encodable
% values. Side effects: creates the parent folder and overwrites the file.

    ensureParent(filepath);
    fid = fopen(filepath, "w", "n", "UTF-8");
    assert(fid > 0, "Unable to open JSONL artifact for writing: %s", filepath);
    cleanup = onCleanup(@() fclose(fid));

    if iscell(records)
        for k = 1:numel(records)
            fprintf(fid, "%s\n", jsonencode(records{k}));
        end
    else
        for k = 1:numel(records)
            fprintf(fid, "%s\n", jsonencode(records(k)));
        end
    end
end

function ensureParent(filepath)
    parent = fileparts(filepath);
    if ~isempty(parent) && exist(parent, "dir") ~= 7
        mkdir(parent);
    end
end
