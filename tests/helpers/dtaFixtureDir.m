function folder = dtaFixtureDir()
%DTAFIXTUREDIR Return the absolute path for DTA test fixtures.

    root = testRepoRoot();
    folder = fullfile(root, 'tests', 'fixtures', 'dta');
end
