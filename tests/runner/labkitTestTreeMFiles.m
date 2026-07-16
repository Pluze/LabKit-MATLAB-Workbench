function files = labkitTestTreeMFiles(root)
%LABKITTESTTREEMFILES Return sorted MATLAB files below a test folder.
% Expected caller: official test discovery and selector discovery.

    if ~isfolder(root)
        files = strings(1, 0);
        return;
    end
    entries = dir(fullfile(root, "**", "*.m"));
    entries = entries(~[entries.isdir]);
    files = sort(string(fullfile({entries.folder}, {entries.name})));
end
