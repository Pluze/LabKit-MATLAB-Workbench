function syncLabKitDocTree(sourceRoot, targetRoot)
%SYNCLABKITDOCTREE Synchronize generated documentation without replacing its root.
% Expected caller: renderLabKitDocs after a complete temporary-tree build.
% Inputs: complete generated source tree and canonical output tree.
% Output: none.
% Side effects: updates changed files, removes stale files and empty folders,
%   and preserves the target root directory for sync-folder compatibility.

    sourceRoot = string(sourceRoot);
    targetRoot = string(targetRoot);
    if ~isfolder(targetRoot)
        mkdir(targetRoot);
    end
    sourceFiles = listLabKitDocTreeFiles(sourceRoot);
    targetFiles = listLabKitDocTreeFiles(targetRoot);
    for k = 1:numel(sourceFiles)
        source = fullfile(sourceRoot, replace(sourceFiles(k), "/", filesep));
        target = fullfile(targetRoot, replace(sourceFiles(k), "/", filesep));
        parent = string(fileparts(target));
        if ~isfolder(parent)
            mkdir(parent);
        end
        if ~isfile(target) || ~sameFileBytes(source, target)
            copyfile(source, target, "f");
        end
    end
    staleFiles = setdiff(targetFiles, sourceFiles, "stable");
    for k = 1:numel(staleFiles)
        delete(fullfile(targetRoot, replace(staleFiles(k), "/", filesep)));
    end
    removeEmptyFolders(targetRoot);
    removeEmptyNumberedSiblings(targetRoot);
end

function removeEmptyNumberedSiblings(root)
    [parent, name] = fileparts(root);
    entries = dir(fullfile(parent, name + " *"));
    pattern = "^" + string(regexptranslate('escape', char(name))) + ...
        " [0-9]+$";
    for k = 1:numel(entries)
        if ~entries(k).isdir || isempty(regexp(entries(k).name, ...
                char(pattern), 'once'))
            continue;
        end
        candidate = string(fullfile(entries(k).folder, entries(k).name));
        if isempty(listLabKitDocTreeFiles(candidate))
            rmdir(candidate, "s");
        end
    end
end

function tf = sameFileBytes(left, right)
    leftInfo = dir(left);
    rightInfo = dir(right);
    if isempty(leftInfo) || isempty(rightInfo) || ...
            leftInfo.bytes ~= rightInfo.bytes
        tf = false;
        return;
    end
    tf = isequal(readBytes(left), readBytes(right));
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

function removeEmptyFolders(root)
    entries = dir(fullfile(root, "**", "*"));
    entries = entries([entries.isdir]);
    paths = strings(numel(entries), 1);
    pathCount = 0;
    for k = 1:numel(entries)
        if any(string(entries(k).name) == [".", ".."])
            continue;
        end
        pathCount = pathCount + 1;
        paths(pathCount, 1) = string(fullfile( ...
            entries(k).folder, entries(k).name));
    end
    paths = paths(1:pathCount);
    [~, order] = sort(strlength(paths), "descend");
    paths = paths(order);
    for k = 1:numel(paths)
        contents = dir(paths(k));
        names = string({contents.name});
        contents = contents(~ismember(names, [".", ".."]));
        if isempty(contents)
            rmdir(paths(k));
        end
    end
end
