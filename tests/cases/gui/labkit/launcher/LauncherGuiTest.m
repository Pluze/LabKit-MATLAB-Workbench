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
    h.assertTabTitles(fig, {'Launcher', 'Selected App', 'Actions'});
    assertNoPanelTitle(fig, {'Filter', 'Search', 'Status', 'Hint'});
    assertNoControlText(fig, {'Search:', 'Family:', 'LabKit Apps', 'Hint'});
    h.assertButtonContract(fig, {'Open Selected App', 'Open Debug', ...
        'Update from GitHub', 'Run Code Analyzer', 'Clean Artifacts', ...
        'Refresh App List'});
    h.assertAnyTableColumns(fig, {'Family', 'App', 'Command'});
    assertLauncherTextAreasHaveRoom(fig);
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
