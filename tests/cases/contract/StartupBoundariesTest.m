classdef StartupBoundariesTest < matlab.unittest.TestCase
    %STARTUPBOUNDARIESTEST Verify LabKit behavior through official MATLAB tests.

    methods (Test, TestTags = {'Integration', 'Style'})
        function test_startup_boundaries(testCase)
            setupLabKitTestPath();
            verify_startup_boundaries();
        end
    end
end

function verify_startup_boundaries()
%TEST_STARTUP_BOUNDARIES Check launcher path and root entrypoint boundaries.

    root = testRepoRoot();

    assert(exist(fullfile(root, 'labkit_launcher.m'), 'file') == 2, 'labkit_launcher.m is missing.');
    assert(exist(fullfile(root, '+labkit', '+dta', 'loadFile.m'), 'file') == 2, 'DTA facade is missing.');
    assert(exist(fullfile(root, 'legacy'), 'dir') == 0, ...
        'unsupported root-level app wrappers should not be tracked.');
    assert(pathContains(fullfile(root, 'apps')), 'setup should add apps/ to the path.');

    apps = discoverLabKitApps();
    for i = 1:height(apps)
        entryFolder = char(apps.Folder(i));
        assert(pathContains(entryFolder), ...
            ['setup should add app entry folders to the path: ' entryFolder]);
        assertNoImplementationPathEntries(entryFolder);
    end
    rootMFiles = dir(fullfile(root, '*.m'));
    rootMNames = string({rootMFiles.name});
    allowedRootMFiles = ["buildfile.m", "labkit_launcher.m"];
    unexpectedRootMFiles = setdiff(rootMNames, allowedRootMFiles);
    assert(isempty(unexpectedRootMFiles), ...
        ['Root-level MATLAB files should stay limited to project entrypoints. ' ...
        'App launch wrappers belong under apps/: ' ...
        strjoin(cellstr(unexpectedRootMFiles), ', ')]);

    assert(exist(dtaFixturePath('cv_cyclic_voltammetry_pt_reference.DTA'), 'file') == 2, ...
        'DTA fixture cv_cyclic_voltammetry_pt_reference.DTA is missing.');

    previousDir = pwd;
    cleaner = onCleanup(@() cd(previousDir));
    cd(tempdir);
    for i = 1:height(apps)
        command = char(apps.Command(i));
        assert(~isempty(which(command)), ...
            ['App entry point should resolve without cd into apps/: ' command]);
    end

end

function tf = pathContains(folder)
    paths = strsplit(path, pathsep);
    tf = any(strcmp(paths, folder));
end

function assertNoImplementationPathEntries(entryFolder)
    packageDirs = dir(fullfile(entryFolder, '+*'));
    for k = 1:numel(packageDirs)
        if packageDirs(k).isdir
            folder = fullfile(packageDirs(k).folder, packageDirs(k).name);
            assert(~pathContains(folder), ...
                ['setup should not expose app-owned package folders as direct path entries: ' folder]);
        end
    end

    privateFolder = fullfile(entryFolder, 'private');
    assert(~pathContains(privateFolder), ...
        ['setup should not expose app-private helper folders as public path entries: ' privateFolder]);
end
