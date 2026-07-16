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
    [status, attributes] = fileattrib(root);
    if ~status
        error("LabKit:Docs:UnreadableTree", ...
            "Could not resolve documentation tree: %s", string(root));
    end
    root = string(attributes.Name);
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
    for k = 1:numel(rootHiddenFiles)
        if isfile(fullfile(root, rootHiddenFiles(k))) && ...
                ~any(files == rootHiddenFiles(k))
            files(end + 1, 1) = rootHiddenFiles(k);
        end
    end
    files = sort(unique(files));
end
