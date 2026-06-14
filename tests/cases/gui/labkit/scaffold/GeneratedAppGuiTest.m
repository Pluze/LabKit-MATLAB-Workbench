classdef GeneratedAppGuiTest < matlab.uitest.TestCase
    %GENERATEDAPPGUITEST Verify scaffold output launches as ordinary code.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function generated_app_launches(testCase)
            setupLabKitTestPath();
            verify_generated_app_launch();
        end
    end
end

function verify_generated_app_launch()
%VERIFY_GENERATED_APP_LAUNCH Verify generated app debug launch plumbing.

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

function assertUifigureAvailable()
    try
        f = uifigure('Visible', 'off', 'Name', 'labkit_gui_probe');
        delete(f);
    catch ME
        error('GUI tests require MATLAB uifigure support: %s', ME.message);
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
