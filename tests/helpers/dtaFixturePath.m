function filepath = dtaFixturePath(filename)
%DTAFIXTUREPATH Return the absolute path for a named DTA test fixture.

    filepath = fullfile(dtaFixtureDir(), filename);
end
