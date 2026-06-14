classdef AppLaunchSmokeTest < matlab.uitest.TestCase
    %APPLAUNCHSMOKETEST Verify launchable LabKit apps through discovery.

    methods (Test, TestTags = {'GUI', 'Structural', 'Smoke'})
        function test_labkit_launcher_layout(testCase)
            setupLabKitTestPath();
            verify_labkit_launcher_layout();
        end

        function test_gui_smoke(testCase)
            setupLabKitTestPath();
            verify_gui_smoke();
        end

        function generated_app_launches(testCase)
            setupLabKitTestPath();
            verify_generated_app_smoke();
        end
    end
end

function verify_labkit_launcher_layout()
%VERIFY_LABKIT_LAUNCHER_LAYOUT Verify root launcher layout and app discovery.

    h = guiTestHelpers();
    h.assertUifigureAvailable();
    cleanup = onCleanup(@() h.closeAllFigures());

    apps = discoverLabKitApps();

    fig = labkit_launcher();
    drawnow;
    assert(strcmp(fig.Name, 'LabKit App Launcher'), ...
        'labkit_launcher should return the launcher figure handle.');
    h.assertFigureMinimumSize(fig, 1320, 760);
    h.assertTabTitles(fig, {'Launcher', 'Selected App', 'Actions'});
    assertNoPanelTitle(fig, {'Filter', 'Search', 'Status', 'Hint'});
    assertNoControlText(fig, {'Search:', 'Family:', 'LabKit Apps', 'Hint'});
    h.assertButtonContract(fig, {'Open Selected App', 'Open Debug', ...
        'Project Governance', 'Clean Artifacts', 'Refresh App List'});
    h.assertAnyTableColumns(fig, {'Family', 'App', 'Command'});
    h.invokeButton(fig, 'Refresh App List');
end

function assertNoPanelTitle(fig, blockedTitles)
    actual = titleValues(fig);
    for k = 1:numel(blockedTitles)
        assert(~any(actual == string(blockedTitles{k})), ...
            'Launcher should not draw a separate "%s" filter panel.', blockedTitles{k});
    end
end

function assertNoControlText(fig, blockedTexts)
    actual = textValues(fig);
    for k = 1:numel(blockedTexts)
        assert(~any(actual == string(blockedTexts{k})), ...
            'Launcher should not draw "%s".', blockedTexts{k});
    end
end

function values = titleValues(fig)
    controls = findall(fig);
    values = strings(0, 1);
    for k = 1:numel(controls)
        if isprop(controls(k), 'Title')
            values(end + 1, 1) = string(controls(k).Title);
        end
    end
end

function values = textValues(fig)
    controls = findall(fig);
    values = strings(0, 1);
    for k = 1:numel(controls)
        if isprop(controls(k), 'Text')
            values(end + 1, 1) = string(controls(k).Text);
        end
    end
end

function verify_gui_smoke()
%TEST_GUI_SMOKE Verify GUI entry points can launch.

    assertUifigureAvailable();
    root = testRepoRoot();
    legacyDir = fullfile(root, 'legacy');

    apps = discoverLabKitApps();

    cleanup = onCleanup(@closeAllFigures);
    for k = 1:height(apps)
        closeAllFigures();
        entryName = char(apps.Command(k));
        fprintf('Smoke launching %s (%d/%d).\n', entryName, k, height(apps));

        feval(entryName);
        drawnow;
        assert(~pathContains(legacyDir), 'Entry point %s should not leave legacy/ on the MATLAB path.', entryName);
        assertLaunchedFigure(entryName);

        closeAllFigures();
        [fig, debug] = feval(entryName, "debug");
        drawnow;
        assert(isstruct(debug) && debug.enabled, ...
            'Debug launch for %s should return an enabled debug log struct.', entryName);
        assert(debug.appName == string(entryName), ...
            'Debug launch for %s should preserve the app name.', entryName);
        assert(isfield(debug, 'getLog') && isa(debug.getLog, 'function_handle'), ...
            'Debug launch for %s should return a getLog function.', entryName);
        assert(strlength(debug.logFile) > 0 && exist(char(debug.logFile), 'file') == 2, ...
            'Debug launch for %s should create an app debug log artifact.', entryName);
        lines = string(debug.getLog());
        assert(any(contains(lines, 'debug trace enabled')), ...
            'Debug launch for %s should emit a startup trace line.', entryName);
        assertVisibleDebugTrace(fig, entryName);
    end
end

function verify_generated_app_smoke()
%VERIFY_GENERATED_APP_SMOKE Verify scaffold output launches as ordinary code.

    assertUifigureAvailable();
    tempRoot = tempname;

    created = project_governance.ops.createLabKitApp( ...
        "Root", tempRoot, ...
        "Family", "bench_tools", ...
        "Slug", "surface_scan", ...
        "EntryPoint", "labkit_SurfaceScan_app", ...
        "Label", "Surface Scan");

    appFolder = char(created.AppFolder);
    addpath(appFolder);
    cleanup = onCleanup(@() cleanupGeneratedApp(tempRoot, appFolder));

    [fig, debug] = labkit_SurfaceScan_app("debug");
    drawnow;

    assert(strcmp(fig.Name, 'Surface Scan'), ...
        'Generated app should launch with the requested window label.');
    assert(isstruct(debug) && debug.enabled, ...
        'Generated app debug launch should return an enabled debug log struct.');
    assert(debug.appName == "labkit_SurfaceScan_app", ...
        'Generated app debug context should preserve the generated app name.');
    assert(strlength(debug.logFile) > 0 && exist(char(debug.logFile), 'file') == 2, ...
        'Generated app debug launch should create a debug log artifact.');
    assertVisibleDebugTrace(fig, 'labkit_SurfaceScan_app');
end

function assertLaunchedFigure(entryName)
    figs = findall(groot, 'Type', 'figure');
    assert(~isempty(figs), 'GUI entry point %s did not create a figure.', entryName);

    names = getFigureNames(figs);
    assert(any(strlength(string(names)) > 0), ...
        'GUI entry point %s should create a named figure.', entryName);
end

function tf = pathContains(folder)
    paths = strsplit(path, pathsep);
    tf = any(strcmp(paths, folder));
end

function assertUifigureAvailable()
    try
        f = uifigure('Visible', 'off', 'Name', 'labkit_gui_smoke_probe');
        delete(f);
    catch ME
        error('GUI smoke tests require MATLAB uifigure support: %s', ME.message);
    end
end

function names = getFigureNames(figs)
    names = cell(size(figs));
    for i = 1:numel(figs)
        names{i} = figs(i).Name;
    end
end

function closeAllFigures()
    figs = findall(groot, 'Type', 'figure');
    if ~isempty(figs)
        delete(figs);
    end
    drawnow;
end

function cleanupGeneratedApp(tempRoot, appFolder)
    closeAllFigures();
    if contains(path, appFolder)
        rmpath(appFolder);
    end
    if exist(tempRoot, "dir") == 7
        rmdir(tempRoot, "s");
    end
end

function assertVisibleDebugTrace(fig, entryName)
    controls = findall(fig);
    for iControl = 1:numel(controls)
        control = controls(iControl);
        if ~contains(class(control), 'TextArea')
            continue;
        end
        values = string(control.Value);
        if any(contains(values, 'debug trace enabled'))
            return;
        end
    end
    error('Debug launch for %s should mirror trace lines into the visible Log tab.', entryName);
end
