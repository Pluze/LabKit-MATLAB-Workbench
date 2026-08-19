function files = listLabKitDocTreeFiles(root)
%LISTLABKITDOCTREEFILES List generated documentation files by relative path.
% Expected caller: documentation tree comparison and synchronization.
% Input: root documentation-tree folder.
% Output: sorted string column of slash-separated relative file paths.
% Side effects: none. Platform metadata files are excluded.

    if ~isfolder(root)
        files = strings(0, 1);
        return;
    end
    root = resolveLabKitDocFolder(root, ...
        "LabKit:Docs:UnreadableTree", ...
        "Could not resolve documentation tree: %s");
    entries = dir(fullfile(root, "**", "*"));
    entries = entries(~[entries.isdir]);
    entries = entries(~ismember(string({entries.name}), ...
        [".DS_Store", "Thumbs.db"]));
    files = strings(numel(entries), 1);
    prefix = string(root) + filesep;
    for k = 1:numel(entries)
        filepath = string(fullfile(entries(k).folder, entries(k).name));
        files(k) = replace(extractAfter(filepath, strlength(prefix)), ...
            filesep, "/");
    end
    rootHiddenFiles = ".nojekyll";
    rootHiddenPresent = strings(numel(rootHiddenFiles), 1);
    presentCount = 0;
    for k = 1:numel(rootHiddenFiles)
        if isfile(fullfile(root, rootHiddenFiles(k))) && ...
                ~any(files == rootHiddenFiles(k))
            presentCount = presentCount + 1;
            rootHiddenPresent(presentCount) = rootHiddenFiles(k);
        end
    end
    files = [files; rootHiddenPresent(1:presentCount)];
    files = sort(unique(files));
end
