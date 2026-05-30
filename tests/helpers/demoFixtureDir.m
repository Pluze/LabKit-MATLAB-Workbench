function folder = demoFixtureDir()
%DEMOFIXTUREDIR Return the absolute path for the demo fixture directory.

    root = testRepoRoot();
    folder = fullfile(root, 'demo');
end
