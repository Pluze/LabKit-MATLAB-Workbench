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
%TEST_STARTUP_BOUNDARIES Check startup path and root entrypoint boundaries.

    root = testRepoRoot();

    assert(exist(fullfile(root, 'startup_labkit.m'), 'file') == 2, 'startup_labkit.m is missing.');
    assert(exist(fullfile(root, '+labkit', '+dta', 'loadFile.m'), 'file') == 2, 'DTA facade is missing.');
    assert(exist(fullfile(root, 'legacy'), 'dir') == 0, 'legacy/ should be removed after app entry points are package-backed.');
    assert(pathContains(fullfile(root, 'apps')), 'startup_labkit should add apps/ to the path.');

    apps = discoverLabKitApps();
    for i = 1:height(apps)
        entryFolder = char(apps.Folder(i));
        assert(pathContains(entryFolder), ...
            ['startup_labkit should add app entry folders to the path: ' entryFolder]);
        assertNoImplementationPathEntries(entryFolder);
    end
    assert(~pathContains(fullfile(root, 'apps', 'project', 'governance', 'scaffold')), ...
        'startup_labkit should not expose governance scaffold source as a path entry.');
    assert(~pathContains(fullfile(root, 'apps', 'project', 'governance', 'scaffold', 'generated_app')), ...
        'startup_labkit should not expose generated-app scaffold source as a path entry.');

    removedRootNames = { ...
        'gamry_CIC_VT_gui_paperlabels', ...
        'gamry_VT_resistance_gui', ...
        'gamry_CV_CSC_dta_gui', ...
        'gamry_EIS_multiDTA_plot_gui', ...
        'gamry_multiDTA_plot_export_gui'};

    for i = 1:numel(removedRootNames)
        rootFile = fullfile(root, [removedRootNames{i} '.m']);

        assert(exist(rootFile, 'file') == 0, ['Root legacy wrapper should be removed: ' removedRootNames{i}]);
        assert(isempty(which(removedRootNames{i})), ['Original legacy command should not resolve by default: ' removedRootNames{i}]);
    end

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

    verifyStartupRefreshesNewAppDirs(root);
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
                ['startup_labkit should not expose app-owned package folders as direct path entries: ' folder]);
        end
    end

    privateFolder = fullfile(entryFolder, 'private');
    assert(~pathContains(privateFolder), ...
        ['startup_labkit should not expose app-private helper folders as public path entries: ' privateFolder]);
end

function verifyStartupRefreshesNewAppDirs(root)
    startup_labkit(false);

    probeDir = fullfile(root, 'apps', 'project', 'startup_refresh_probe');
    cleanup = onCleanup(@() cleanupProbeDir(probeDir));
    if exist(probeDir, 'dir') == 7
        rmdir(probeDir, 's');
    end
    mkdir(probeDir);
    assert(~pathContains(probeDir), ...
        'New app folder should not be on path before startup refresh.');

    startup_labkit(false);

    assert(pathContains(probeDir), ...
        'startup_labkit should refresh app folders created after the first startup call.');
end

function cleanupProbeDir(probeDir)
    if pathContains(probeDir)
        rmpath(probeDir);
    end
    if exist(probeDir, 'dir') == 7
        rmdir(probeDir, 's');
    end
end
