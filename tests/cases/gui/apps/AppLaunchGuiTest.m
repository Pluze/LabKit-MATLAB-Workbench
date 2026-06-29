classdef AppLaunchGuiTest < matlab.uitest.TestCase
    %APPLAUNCHGUITEST Verify existing LabKit app entry points launch.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function app_entrypoints_launch(testCase)
            setupLabKitTestPath();
            verify_app_entrypoint_launches();
        end
    end
end

function verify_app_entrypoint_launches()
%VERIFY_APP_ENTRYPOINT_LAUNCHES Verify app entry points not covered elsewhere.

    assertUifigureAvailable();
    root = testRepoRoot();
    legacyDir = fullfile(root, 'legacy');

    apps = appsWithoutDedicatedLayoutTests(root, discoverLabKitApps());
    assert(height(apps) > 0, ...
        'Launch smoke should cover apps that do not have dedicated GUI layout tests.');

    cleanup = onCleanup(@closeAllFigures);
    for k = 1:height(apps)
        closeAllFigures();
        entryName = char(apps.Command(k));
        fprintf('App launching %s (%d/%d).\n', entryName, k, height(apps));

        [fig, debug] = feval(entryName, "debug");
        drawnow;
        assert(~pathContains(legacyDir), ...
            'Entry point %s should not leave legacy/ on the MATLAB path.', entryName);
        assertLaunchedFigure(entryName);
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

function apps = appsWithoutDedicatedLayoutTests(root, apps)
    keep = true(height(apps), 1);
    for k = 1:height(apps)
        keep(k) = ~hasDedicatedLayoutTest(root, apps.Folder(k), apps.Command(k));
    end
    apps = apps(keep, :);
end

function tf = hasDedicatedLayoutTest(root, appFolder, command)
    appFolder = char(appFolder);
    command = string(command);
    appsRoot = fullfile(root, 'apps');
    rel = appFolder;
    prefix = [appsRoot filesep];
    if startsWith(appFolder, prefix)
        rel = appFolder(numel(prefix)+1:end);
    end
    relParts = split(string(strrep(rel, filesep, '/')), '/');
    if numel(relParts) >= 2
        guiFolder = fullfile(root, 'tests', 'cases', 'gui', 'apps', ...
            char(relParts(1)), char(relParts(2)));
        tf = isfolder(guiFolder) && ~isempty(dir(fullfile(guiFolder, '*.m')));
        if tf
            return;
        end
    end

    tf = false;
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
        f = uifigure('Visible', 'off', 'Name', 'labkit_gui_probe');
        delete(f);
    catch ME
        error('GUI tests require MATLAB uifigure support: %s', ME.message);
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
