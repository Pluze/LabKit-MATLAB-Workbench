function [matches, diagnostic, comparedCount] = compareLabKitDocTrees(leftRoot, rightRoot)
%COMPARELABKITDOCTREES Compare generated documentation trees byte-for-byte.

    left = relativeFiles(leftRoot);
    right = relativeFiles(rightRoot);
    comparedCount = numel(left);
    if ~isequal(left, right)
        matches = false;
        diagnostic = "generated file lists differ";
        return;
    end
    for k = 1:numel(left)
        leftBytes = readBytes(fullfile(leftRoot, left(k)));
        rightBytes = readBytes(fullfile(rightRoot, right(k)));
        if ~isequal(leftBytes, rightBytes)
            matches = false;
            diagnostic = "content differs for " + left(k);
            return;
        end
    end
    matches = true;
    diagnostic = "";
end

function files = relativeFiles(root)
    if ~isfolder(root)
        files = strings(0, 1);
        return;
    end
    entries = dir(fullfile(root, "**", "*"));
    entries = entries(~[entries.isdir]);
    entries = entries(~ismember(string({entries.name}), ...
        [".DS_Store", "Thumbs.db"]));
    files = strings(numel(entries), 1);
    prefix = string(root) + filesep;
    for k = 1:numel(entries)
        filepath = string(fullfile(entries(k).folder, entries(k).name));
        files(k) = replace(extractAfter(filepath, strlength(prefix)), filesep, "/");
    end
    files = sort(files);
end

function bytes = readBytes(filepath)
    fid = fopen(filepath, "r");
    if fid < 0
        bytes = uint8.empty(0, 1);
        return;
    end
    cleanup = onCleanup(@() fclose(fid));
    bytes = fread(fid, Inf, "*uint8");
    clear cleanup
end
