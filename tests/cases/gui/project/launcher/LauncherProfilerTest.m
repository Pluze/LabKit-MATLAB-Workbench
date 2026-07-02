classdef LauncherProfilerTest < matlab.uitest.TestCase
    %LAUNCHERPROFILERTEST Verify launcher-managed app profiling.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function performance_profile_action_uses_profile_tool(testCase)
            root = setupLabKitTestPath();
            source = fileread(fullfile(root, "labkit_launcher.m"));
            body = launcherFunctionBlock(source, ...
                '%% Section: Performance profile action', ...
                'function value = stringField(raw, name)');

            testCase.verifyFalse(isempty(strfind(body, 'profileLabKitTarget(')), ...
                'Launcher performance profile action should use the shared profileLabKitTarget tool.');
            testCase.verifyFalse(isempty(strfind(body, '''WaitForGuiClose'', true')), ...
                'Launcher performance profile should continue until the launched app window closes.');
            testCase.verifyFalse(isempty(strfind(body, ...
                '''artifacts'', ''profile'', ''launcher-app-session''')), ...
                'Launcher performance profile reports should use the launcher app-session artifact folder.');
        end

        function performance_profile_button_writes_profile_report(testCase)
            root = setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            h.closeAllFigures();
            cleanupMode = setGuiTestModeForTest("hidden");
            cleanupFigures = onCleanup(@() h.closeAllFigures());

            tempRoot = string(tempname);
            mkdir(tempRoot);
            testCase.addTeardown(@() removeFolderIfPresent(tempRoot));
            copyfile(fullfile(root, "labkit_launcher.m"), ...
                fullfile(tempRoot, "labkit_launcher.m"));
            mkdir(fullfile(tempRoot, "tools"));
            copyfile(fullfile(root, "tools", "profiling"), ...
                fullfile(tempRoot, "tools", "profiling"));
            createProfileProbeApp(tempRoot);
            testCase.addTeardown(@() removePathIfPresent( ...
                fullfile(tempRoot, "apps", "probe")));
            originalFolder = pwd;
            cd(tempRoot);
            testCase.addTeardown(@() cd(originalFolder));
            clear labkit_launcher;

            fig = labkit_launcher();
            drawnow;
            h.invokeButton(fig, 'Profile Next App');
            h.invokeButton(fig, 'Open Selected App');
            drawnow;

            outputRoot = fullfile(tempRoot, "artifacts", "profile", ...
                "launcher-app-session");
            htmlFiles = dir(fullfile(outputRoot, "profile_labkit_ProfileProbe_app_*.html"));
            jsonFiles = dir(fullfile(outputRoot, "profile_labkit_ProfileProbe_app_*.json"));
            testCase.verifyNotEmpty(htmlFiles, ...
                'Performance profile should write an HTML report for the launched app session.');
            testCase.verifyNotEmpty(jsonFiles, ...
                'Performance profile should write a JSON sidecar for the launched app session.');
            assertInfoContains(fig, "Profile complete for labkit_ProfileProbe_app");

            clear cleanupMode cleanupFigures;
            h.closeAllFigures();
            clear labkit_launcher;
            cd(originalFolder);
        end
    end
end

function cleanup = setGuiTestModeForTest(mode)
    previous = getenv('LABKIT_GUI_TEST_MODE');
    setenv('LABKIT_GUI_TEST_MODE', char(mode));
    cleanup = onCleanup(@() setenv('LABKIT_GUI_TEST_MODE', previous));
end

function block = launcherFunctionBlock(source, startMarker, endMarker)
    startIndex = strfind(source, startMarker);
    endIndex = strfind(source, endMarker);
    assert(~isempty(startIndex), 'Launcher source block start not found: %s', startMarker);
    assert(~isempty(endIndex), 'Launcher source block end not found: %s', endMarker);
    assert(startIndex(1) < endIndex(1), ...
        'Launcher source block markers are out of order.');
    block = source(startIndex(1):endIndex(1)-1);
end

function createProfileProbeApp(root)
    folder = fullfile(root, "apps", "probe");
    if exist(folder, "dir") ~= 7
        mkdir(folder);
    end
    writeText(fullfile(folder, "labkit_ProfileProbe_app.m"), sprintf([ ...
        'function varargout = labkit_ProfileProbe_app(varargin)\n' ...
        '%%LABKIT_PROFILEPROBE_APP Generated launcher profile probe.\n' ...
        'fig = uifigure(''Visible'', ''off'', ''Name'', ''Profile Probe'');\n' ...
        'drawnow;\n' ...
        'close(fig);\n' ...
        'if nargout > 0\n' ...
        '    varargout = {[]};\n' ...
        'end\n' ...
        'end\n']));
end

function assertInfoContains(fig, expectedText)
    ui = getappdata(fig, 'labkitUiRegistry');
    value = string(ui.controls.statusLine.textArea.Value);
    assert(any(contains(value, expectedText)), ...
        'Launcher info text should include: %s', expectedText);
end

function removeFolderIfPresent(folder)
    if exist(folder, "dir") == 7
        folderOnPath = any(string(strsplit(path, pathsep)) == string(folder));
        if folderOnPath
            rmpath(folder);
        end
        rmdir(folder, "s");
    end
end

function removePathIfPresent(folder)
    if pathContainsExact(folder)
        rmpath(char(folder));
    end
end

function tf = pathContainsExact(folder)
    paths = string(strsplit(path, pathsep));
    if ispc
        tf = any(strcmpi(paths, string(folder)));
    else
        tf = any(strcmp(paths, string(folder)));
    end
end

function writeText(filepath, text)
    fid = fopen(filepath, 'w');
    assert(fid > 0, 'Could not create launcher profile test file: %s', filepath);
    cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, '%s', text);
end
