classdef LauncherGuiTest < matlab.uitest.TestCase
    %LAUNCHERGUITEST Verify the root launcher without launching every app.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function launcher_list_mode_discovers_apps(testCase)
            setupLabKitTestPath();

            apps = labkit_launcher("list");

            testCase.verifyTrue(istable(apps), ...
                'labkit_launcher list mode should return a table.');
            testCase.verifyTrue(all(ismember( ...
                ["Command", "DisplayName", "Family", "Folder", ...
                "RelativePath", "Description"], string(apps.Properties.VariableNames))), ...
                'labkit_launcher list mode should return the app catalog columns.');
            testCase.verifyGreaterThan(height(apps), 0, ...
                'labkit_launcher list mode should discover app entry points.');
        end

        function launcher_layout(testCase)
            setupLabKitTestPath();
            verify_launcher_layout();
        end

        function launcher_runs_when_only_launcher_file_exists(testCase)
            root = setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            h.closeAllFigures();
            cleanupFigures = onCleanup(@() h.closeAllFigures());

            tempRoot = string(tempname);
            mkdir(tempRoot);
            testCase.addTeardown(@() removeFolderIfPresent(tempRoot));
            copyfile(fullfile(root, "labkit_launcher.m"), ...
                fullfile(tempRoot, "labkit_launcher.m"));
            originalFolder = pwd;
            cd(tempRoot);
            testCase.addTeardown(@() cd(originalFolder));
            clear labkit_launcher;

            apps = labkit_launcher("list");
            testCase.verifyTrue(istable(apps));
            testCase.verifyEqual(height(apps), 0);

            fig = labkit_launcher();
            drawnow;
            testCase.verifyEqual(string(fig.Name), "LabKit App Launcher");
            h.assertButtonContract(fig, {'Update from GitHub', ...
                'Refresh App List'});
            assertNoLauncherTabs(fig);
            assertInfoContains(fig, "Use Update from GitHub to repair");
            clear cleanupFigures;
            h.closeAllFigures();
            clear labkit_launcher;
            cd(originalFolder);
        end
    end
end

function verify_launcher_layout()
%VERIFY_LAUNCHER_LAYOUT Verify root launcher layout and local actions.

    h = guiTestHelpers();
    h.assertUifigureAvailable();
    cleanup = onCleanup(@() h.closeAllFigures());

    fig = labkit_launcher();
    drawnow;
    assert(strcmp(fig.Name, 'LabKit App Launcher'), ...
        'labkit_launcher should return the launcher figure handle.');
    h.assertStandardWorkbenchLayout(fig);
    assertNoLauncherTabs(fig);
    assertNoPanelTitle(fig, {'Filter', 'Search', 'Status', 'Hint'});
    assertNoControlText(fig, {'Search:', 'Family:', 'LabKit Apps', 'Hint'});
    h.assertButtonContract(fig, {'Open Selected App', 'Open Debug', ...
        'Update from GitHub', 'Run Code Analyzer', 'Clean Artifacts', ...
        'Refresh App List'});
    assertLauncherButtonOrder(fig, {'Update from GitHub', ...
        'Refresh App List', 'Open Selected App', 'Open Debug', ...
        'Clean Artifacts', 'Run Code Analyzer'});
    h.assertAnyTableColumns(fig, {'Family', 'App', 'Command'});
    assertLauncherTextAreasHaveRoom(fig);
    assertInfoContains(fig, "Project structure looks complete");
    h.invokeButton(fig, 'Refresh App List');
end

function assertLauncherTextAreasHaveRoom(fig)
    drawnow;
    pause(0.5);
    drawnow;
    ui = getappdata(fig, 'labkitUiRegistry');
    assert(isvalid(ui.controls.selectedDetails.textArea) && ...
        ~isempty(ui.controls.selectedDetails.textArea.Value), ...
        'Selected App details should preserve a readable status panel.');
    assert(isvalid(ui.controls.statusLine.textArea) && ...
        ~isempty(ui.controls.statusLine.textArea.Value), ...
        'Launcher action status should preserve a readable status panel.');
end

function assertNoLauncherTabs(fig)
    tabGroups = findall(fig, 'Type', 'uitabgroup');
    assert(isempty(tabGroups), ...
        'Launcher controls should use a single-page layout without tabs.');
end

function assertLauncherButtonOrder(fig, expectedTexts)
    drawnow;
    buttons = findall(fig, 'Type', 'uibutton');
    texts = string(get(buttons, 'Text'));
    positions = cell2mat(get(buttons, 'Position'));
    [~, order] = sort(positions(:, 2), 'descend');
    orderedTexts = texts(order);
    actual = orderedTexts(ismember(orderedTexts, string(expectedTexts)));
    assert(isequal(actual(:), string(expectedTexts(:))), ...
        'Launcher action buttons should stay together in the requested order.');
end

function assertInfoContains(fig, expectedText)
    ui = getappdata(fig, 'labkitUiRegistry');
    value = string(ui.controls.statusLine.textArea.Value);
    assert(any(contains(value, expectedText)), ...
        'Launcher info text should include: %s', expectedText);
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

function removeFolderIfPresent(folder)
    if exist(folder, "dir") == 7
        folderOnPath = any(string(strsplit(path, pathsep)) == string(folder));
        if folderOnPath
            rmpath(folder);
        end
        rmdir(folder, "s");
    end
end
