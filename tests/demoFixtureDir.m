function folder = demoFixtureDir()
%DEMOFIXTUREDIR Return the absolute path for the demo fixture directory.

    root = fileparts(fileparts(mfilename('fullpath')));
    folder = fullfile(root, 'demo');
end
