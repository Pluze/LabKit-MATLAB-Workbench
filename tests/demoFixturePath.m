function filepath = demoFixturePath(filename)
%DEMOFIXTUREPATH Return the absolute path for a named demo fixture.

    filepath = fullfile(demoFixtureDir(), filename);
end
