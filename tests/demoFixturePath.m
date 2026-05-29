function filepath = demoFixturePath(filename)
%DEMOFIXTUREPATH Return the absolute path for a named demo fixture.

    root = fileparts(fileparts(mfilename('fullpath')));
    filepath = fullfile(root, 'demo', filename);
end
