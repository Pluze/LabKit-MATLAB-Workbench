function root = testRepoRoot()
%TESTREPOROOT Return the repository root from any test subfolder.

    root = fileparts(mfilename('fullpath'));
    while true
        if exist(fullfile(root, 'labkit_launcher.m'), 'file') == 2 && ...
                exist(fullfile(root, '+labkit'), 'dir') == 7
            return;
        end

        parent = fileparts(root);
        if strcmp(parent, root)
            error('Could not locate repository root from test path.');
        end
        root = parent;
    end
end
