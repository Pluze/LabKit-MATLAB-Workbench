classdef LauncherGuiTest < matlab.uitest.TestCase
    %LAUNCHERGUITEST Verify the root launcher without launching every app.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function launcher_list_mode_discovers_apps(testCase)
            setupLabKitTestPath();

            apps = labkit_launcher("list");
            info = labkit_launcher("version");

            testCase.verifyTrue(istable(apps), ...
                'labkit_launcher list mode should return a table.');
            testCase.verifyEqual(info.name, "labkit_launcher");
            testCase.verifyMatches(info.version, "^\d+\.\d+\.\d+$");
            testCase.verifyMatches(info.updated, "^\d{4}-\d{2}-\d{2}$");
            testCase.verifyTrue(all(ismember( ...
                ["Command", "DisplayName", "Family", "Folder", ...
                "RelativePath", "Description", "Version", "Updated"], ...
                string(apps.Properties.VariableNames))), ...
                'labkit_launcher list mode should return the app catalog columns.');
            testCase.verifyTrue(all(strlength(apps.Version) > 0 & strlength(apps.Updated) > 0), ...
                'labkit_launcher list mode should expose app version and update dates.');
            testCase.verifyGreaterThan(height(apps), 0, ...
                'labkit_launcher list mode should discover app entry points.');
        end

        function launcher_layout(testCase)
            setupLabKitTestPath();
            verify_launcher_layout();
        end

        function launcher_respects_hidden_gui_test_mode(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanupMode = setGuiTestModeForTest("hidden");
            cleanupFigures = onCleanup(@() h.closeAllFigures());

            fig = labkit_launcher();
            drawnow;
            testCase.verifyEqual(string(fig.Visible), "off", ...
                "LABKIT_GUI_TEST_MODE=hidden should keep launcher test figures off screen.");
            clear cleanupMode cleanupFigures
            h.closeAllFigures();
        end

        function launcher_replaces_existing_launcher_window(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanupMode = setGuiTestModeForTest("hidden");
            cleanupFigures = onCleanup(@() h.closeAllFigures());

            firstFig = labkit_launcher();
            drawnow;
            secondFig = labkit_launcher();
            drawnow;

            testCase.verifyFalse(isvalid(firstFig), ...
                "Starting labkit_launcher again should close the previous launcher window.");
            testCase.verifyTrue(isvalid(secondFig), ...
                "The replacement launcher window should remain open.");
            testCase.verifyEqual(string(secondFig.Tag), "labkit_launcher_main", ...
                "Launcher windows should carry the stable replacement tag.");
            clear cleanupMode cleanupFigures
            h.closeAllFigures();
        end

        function launcher_defers_app_folder_path_setup_until_launch(testCase)
            root = setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            h.closeAllFigures();
            cleanupFigures = onCleanup(@() h.closeAllFigures());

            tempRoot = string(tempname);
            mkdir(tempRoot);
            testCase.addTeardown(@() removeFolderIfPresent(tempRoot));
            copyfile(fullfile(root, "labkit_launcher.m"), fullfile(tempRoot, "labkit_launcher.m"));
            appFolder = createMinimalLauncherApp(tempRoot, "lazy", "labkit_LazyPath_app");
            testCase.addTeardown(@() removePathIfPresent(appFolder));
            originalFolder = pwd;
            cd(tempRoot); clear labkit_launcher;
            testCase.addTeardown(@() cd(originalFolder));
            fig = labkit_launcher();
            drawnow;
            testCase.verifyFalse(pathContainsExact(appFolder));
            h.invokeButton(fig, 'Open Selected App'); drawnow;
            testCase.verifyTrue(pathContainsExact(appFolder));
            clear cleanupFigures;
            h.closeAllFigures();
            clear labkit_launcher;
            cd(originalFolder);
        end

        function clean_artifacts_has_static_safety_guards(testCase)
            root = setupLabKitTestPath();
            source = fileread(fullfile(root, "labkit_launcher.m"));
            body = launcherFunctionBlock(source, ...
                'function result = cleanGeneratedArtifacts(root)', ...
                'function tf = confirmCleanArtifacts(fig)');

            testCase.verifyFalse(isempty(strfind(body, 'targets = {')), ...
                'Clean Artifacts must keep targets as a cell list, not a char array.');
            testCase.verifyFalse(isempty(strfind(body, 'targets = {''artifacts''};')), ...
                'Clean Artifacts should only remove the generated artifacts folder.');
            testCase.verifyTrue(isempty(strfind(body, 'matlab_test')), ...
                'Clean Artifacts should not maintain root-level legacy log cleanup targets.');
            testCase.verifyTrue(isempty(strfind(body, 'matlab_code_check.json')), ...
                'Clean Artifacts should not remove root-level legacy Code Analyzer logs.');
            testCase.verifyTrue(isempty(strfind(body, 'targets = [')), ...
                'Clean Artifacts must not concatenate char paths with square brackets.');
            testCase.verifyFalse(isempty(strfind(body, 'validateCleanArtifactsRoot(root)')), ...
                'Clean Artifacts must validate the project root before deleting files.');
            testCase.verifyFalse(isempty(strfind(body, ...
                'validateCleanArtifactsTarget(root, target, relativeTarget);')), ...
                'Clean Artifacts must validate each target before deleting files.');
            verifyTargetValidationBeforeDeletion(testCase, body);
        end

        function code_analyzer_action_uses_codeIssues(testCase)
            root = setupLabKitTestPath();
            source = fileread(fullfile(root, "labkit_launcher.m"));
            body = launcherFunctionBlock(source, ...
                '%% Section: Code Analyzer action', ...
                '%% Section: Update entrypoints and install transaction');

            testCase.verifyFalse(isempty(strfind(body, 'codeIssues(')), ...
                'Launcher Code Analyzer action should use the codeIssues API.');
            testCase.verifyTrue(isempty(strfind(body, 'checkcode(')), ...
                'Launcher Code Analyzer action should not keep the old checkcode scan loop.');
        end

        function code_analyzer_button_writes_codeIssues_report(testCase)
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
            createCodeIssuesProbeApp(tempRoot);
            originalFolder = pwd;
            cd(tempRoot);
            testCase.addTeardown(@() cd(originalFolder));
            clear labkit_launcher;

            fig = labkit_launcher();
            drawnow;
            h.invokeButton(fig, 'Run Code Analyzer');
            reportPath = fullfile(tempRoot, "artifacts", "code-check", ...
                "matlab_code_issues.json");
            testCase.verifyTrue(isfile(reportPath), ...
                'Run Code Analyzer should write the native codeIssues report.');
            testCase.verifyFalse(isfile(fullfile(tempRoot, "artifacts", ...
                "code-check", "matlab_code_check.json")), ...
                'Run Code Analyzer should not keep the old launcher JSON schema.');

            reportText = string(fileread(reportPath));
            testCase.verifyTrue(contains(reportText, ...
                "labkit_CodeIssuesProbe_app.m"), ...
                'Report should include issues from the generated probe app.');
            testCase.verifyTrue(contains(reportText, '"CheckID"'), ...
                'Report should use the native codeIssues field names.');
            testCase.verifyTrue(contains(reportText, '"NOPRT"'), ...
                'Report should preserve codeIssues CheckID values.');
            clear cleanupFigures;
            h.closeAllFigures();
            clear labkit_launcher;
            cd(originalFolder);
        end

        function update_snapshots_runtime_before_whole_folder_replacement(testCase)
            root = setupLabKitTestPath();
            source = fileread(fullfile(root, "labkit_launcher.m"));
            body = launcherFunctionBlock(source, ...
                'function result = launcherUpdateFromZipSource(root, source, progressFcn, preflightDone)', ...
                'function source = resolveStableZipSource()');

            testCase.verifyFalse(isempty(strfind(body, ...
                'removedApps = removedAppEntrypoints(root, sourceRoot);')), ...
                'Updater must compare app entrypoints before applying an update.');
            testCase.verifyFalse(isempty(strfind(body, ...
                'confirmDestructiveUpdate(source.label, removedApps)')), ...
                'Updater must confirm candidate updates that remove app entrypoints.');
            testCase.verifyFalse(isempty(strfind(body, ...
                'moveCurrentInstallToSnapshot(root, progressFcn)')), ...
                'Updater should move the current runtime into a dated snapshot first.');
            testCase.verifyFalse(isempty(strfind(body, ...
                'copyReplacementTree(sourceRoot, root, progressFcn)')), ...
                'Updater should copy the downloaded root as a whole replacement.');
            testCase.verifyTrue(isempty(strfind(body, 'collectManagedFiles(')), ...
                'Updater should not build a managed-file overlay list.');
            testCase.verifyTrue(isempty(strfind(body, 'writeManifest(')), ...
                'Updater should not write a managed install manifest.');
            testCase.verifyTrue(isempty(strfind(source, ...
                'function assertNoUnmanagedInstallFiles(root)')), ...
                'Updater should not keep an unmanaged-file refusal helper.');
        end

        function update_snapshot_and_replacement_helpers_stay_simple(testCase)
            root = setupLabKitTestPath();
            source = fileread(fullfile(root, "labkit_launcher.m"));
            snapshotBody = launcherFunctionBlock(source, ...
                'function [snapshotFolder, movedCount] = moveCurrentInstallToSnapshot(root, progressFcn)', ...
                'function snapshotFolder = uniqueInstallSnapshotFolder(root)');
            copyBody = launcherFunctionBlock(source, ...
                'function copiedCount = copyReplacementTree(sourceRoot, root, progressFcn)', ...
                'function entries = installRootEntries(root)');

            testCase.verifyFalse(isempty(strfind(source, 'LabKit-previous-')), ...
                'Runtime snapshots should use a visible dated LabKit-previous-* folder.');
            testCase.verifyFalse(isempty(strfind(snapshotBody, 'movefile(source, target, "f")')), ...
                'Snapshot should move existing top-level items instead of copying them.');
            testCase.verifyFalse(isempty(strfind(copyBody, 'copyfile(source, target, "f")')), ...
                'Replacement should copy the downloaded top-level entries as-is.');
            testCase.verifyFalse(isempty(strfind(source, 'dir(fullfile(root, ".*"))')), ...
                'Replacement should include dot-prefixed top-level repository entries.');
            testCase.verifyFalse(isempty(strfind(source, 'notifyTopLevelProgress(')), ...
                'Snapshot and replacement should report top-level progress.');
            testCase.verifyTrue(isempty(strfind(source, ...
                'function tf = binaryFilesMatch(leftPath, rightPath)')), ...
                'Whole-folder replacement should not keep byte-compare overlay helpers.');
        end

        function version_manager_uses_update_safety_path(testCase)
            root = setupLabKitTestPath();
            source = fileread(fullfile(root, "labkit_launcher.m"));
            body = launcherFunctionBlock(source, ...
                'function manager = openVersionManager(parentFig, root, refreshCallback, statusCallback)', ...
                'function notifyStatus(statusCallback, message)');

            testCase.verifyFalse(isempty(strfind(body, 'recentVersionSources()')), ...
                'Version manager should fetch selectable release/tag/commit options.');
            testCase.verifyFalse(isempty(strfind(body, ...
                'launcherUpdateFromZipSource(root, source,')), ...
                'Version manager must reuse the normal guarded zip update path.');
            testCase.verifyFalse(isempty(strfind(source, ...
                'Update policy: the current runtime folder is moved into a dated LabKit-previous-* snapshot before replacement.')), ...
                'Version manager should describe snapshot replacement instead of refusing unmanaged files.');
            testCase.verifyTrue(isempty(strfind(source, '.labkit-managed-files.txt')), ...
                'Launcher update policy should not depend on a managed-install manifest.');
            testCase.verifyTrue(isempty(strfind(source, 'LabKit-backup-')), ...
                'Launcher should not generate or allow backup zip files in the LabKit runtime folder.');
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
            info = labkit_launcher("version");
            testCase.verifyTrue(istable(apps));
            testCase.verifyEqual(height(apps), 0);

            fig = labkit_launcher();
            drawnow;
            testCase.verifyEqual(string(fig.Name), ...
                info.displayName + " v" + info.version + " (" + info.updated + ")");
            h.assertButtonContract(fig, {'Latest', 'Release', 'Versions', ...
                'Refresh App List'});
            assertNoLauncherTabs(fig);
            assertInfoContains(fig, "Use GitHub Update to repair");
            clear cleanupFigures;
            h.closeAllFigures();
            clear labkit_launcher;
            cd(originalFolder);
        end

        function launcher_refresh_handles_added_and_removed_apps(testCase)
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
            createMinimalLauncherApp(tempRoot, "alpha", "labkit_Alpha_app");
            createMinimalLauncherApp(tempRoot, "beta", "labkit_Beta_app");
            originalFolder = pwd;
            cd(tempRoot);
            testCase.addTeardown(@() cd(originalFolder));
            clear labkit_launcher;

            fig = labkit_launcher();
            drawnow;
            ui = getappdata(fig, 'labkitUiRegistry');
            tableHandle = ui.controls.appTable.table;
            betaRow = find(string(tableHandle.Data(:, 5)) == "labkit_Beta_app", 1);
            invokeTableSelection(tableHandle, betaRow);
            createMinimalLauncherApp(tempRoot, "gamma", "labkit_Gamma_app");
            h.invokeButton(fig, 'Refresh App List');
            drawnow;
            assertDetailsCommand(fig, "labkit_Beta_app", ...
                'Adding an app should not move the current launcher selection.');

            delete(fullfile(tempRoot, "apps", "beta", "labkit_Beta_app.m"));
            h.invokeButton(fig, 'Refresh App List');
            drawnow;
            assertDetailsCommand(fig, string(tableHandle.Data{1, 5}), ...
                'Removing the selected app should fall back to the first available app.');
            clear cleanupFigures;
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

function verifyTargetValidationBeforeDeletion(testCase, body)
    validationIndex = strfind(body, ...
        'validateCleanArtifactsTarget(root, target, relativeTarget);');
    rmdirIndex = strfind(body, 'rmdir(target,');
    deleteIndex = strfind(body, 'delete(target);');
    testCase.verifyFalse(isempty(validationIndex), ...
        'Clean Artifacts target validation call is missing.');
    testCase.verifyFalse(isempty(rmdirIndex), ...
        'Clean Artifacts directory deletion call is missing.');
    testCase.verifyFalse(isempty(deleteIndex), ...
        'Clean Artifacts file deletion call is missing.');
    if ~isempty(validationIndex) && ~isempty(rmdirIndex)
        testCase.verifyLessThan(validationIndex(1), rmdirIndex(1), ...
            'Clean Artifacts must validate before rmdir.');
    end
    if ~isempty(validationIndex) && ~isempty(deleteIndex)
        testCase.verifyLessThan(validationIndex(1), deleteIndex(1), ...
            'Clean Artifacts must validate before delete.');
    end
end

function verify_launcher_layout()
%VERIFY_LAUNCHER_LAYOUT Verify root launcher layout and local actions.

    h = guiTestHelpers();
    h.assertUifigureAvailable();
    cleanup = onCleanup(@() h.closeAllFigures());

    fig = labkit_launcher();
    info = labkit_launcher("version");
    drawnow;
    expectedTitle = info.displayName + " v" + info.version + " (" + info.updated + ")";
    assert(strcmp(fig.Name, expectedTitle), ...
        'labkit_launcher should return the launcher figure handle.');
    assertCompactLauncherLayout(fig);
    assertNoLauncherTabs(fig);
    assertNoPanelTitle(fig, {'Filter', 'Search', 'Status', 'Hint', ...
        'GitHub Update'});
    assertControlText(fig, 'GitHub download');
    assertNoControlText(fig, {'Search:', 'Family:', 'LabKit Apps', 'Hint'});
    assertLauncherFontSizes(fig);
    assertLauncherTableDensity(fig);
    h.assertButtonContract(fig, {'Open Selected App', 'Open Debug', ...
        'Latest', 'Release', 'Versions', 'Run Code Analyzer', 'Clean Artifacts', ...
        'Refresh App List'});
    assertLauncherButtonOrder(fig, {'Latest', 'Release', 'Versions', ...
        'Refresh App List', 'Open Selected App', 'Open Debug', ...
        'Clean Artifacts', 'Run Code Analyzer'});
    assertUpdateButtonRow(fig);
    h.assertAnyTableColumns(fig, {'Family', 'App', 'Version', 'Updated', 'Command'});
    assertLauncherTextAreasHaveRoom(fig);
    assertInfoContains(fig, "Project structure looks complete");
    assertRefreshPreservesSelectedApp(fig, h);
end

function assertRefreshPreservesSelectedApp(fig, h)
    ui = getappdata(fig, 'labkitUiRegistry');
    tableHandle = ui.controls.appTable.table;
    if size(tableHandle.Data, 1) < 2
        return;
    end
    targetRow = 2;
    expectedCommand = string(tableHandle.Data{targetRow, 5});
    invokeTableSelection(tableHandle, targetRow);
    h.invokeButton(fig, 'Refresh App List');
    drawnow;
    details = string(ui.controls.selectedDetails.textArea.Value);
    assert(any(contains(details, "Command: " + expectedCommand)), ...
        'Refreshing the launcher app list should preserve the selected app when it still exists.');
end

function assertDetailsCommand(fig, expectedCommand, message)
    ui = getappdata(fig, 'labkitUiRegistry');
    details = string(ui.controls.selectedDetails.textArea.Value);
    assert(any(contains(details, "Command: " + string(expectedCommand))), message);
end

function invokeTableSelection(tableHandle, row)
    event = struct('Selection', [row 1], 'Indices', [row 1]);
    if isprop(tableHandle, 'SelectionChangedFcn') && ~isempty(tableHandle.SelectionChangedFcn)
        tableHandle.SelectionChangedFcn(tableHandle, event);
    else
        tableHandle.CellSelectionCallback(tableHandle, event);
    end
end

function folder = createMinimalLauncherApp(root, family, command)
    folder = fullfile(root, "apps", family);
    mkdir(folder);
    writeText(fullfile(folder, command + ".m"), sprintf([ ...
        'function varargout = %s(varargin)\n' ...
        '%%%s Minimal launcher test app.\n' ...
        'if nargout > 0\n' ...
        '    varargout = {[]};\n' ...
        'end\n' ...
        'end\n'], command, upper(command)));
end

function createCodeIssuesProbeApp(root)
    folder = fullfile(root, "apps", "probe");
    mkdir(folder);
    writeText(fullfile(folder, "labkit_CodeIssuesProbe_app.m"), sprintf([ ...
        'function varargout = labkit_CodeIssuesProbe_app(varargin)\n' ...
        '%%LABKIT_CODEISSUESPROBE_APP Generated launcher codeIssues probe.\n' ...
        'value = 1\n' ...
        'if nargout > 0\n' ...
        '    varargout = {value};\n' ...
        'end\n' ...
        'end\n']));
end

function assertCompactLauncherLayout(fig)
    pos = fig.Position;
    assert(pos(3) <= 1300 && pos(4) <= 660 && pos(3) >= 1220 && pos(4) >= 580, ...
        'Launcher should open in a compact but not cramped default window.');
    mainGrid = findLauncherMainGrid(fig);
    columns = mainGrid.ColumnWidth;
    assert(numel(columns) == 3 && isequal(columns{1}, 360) && ...
        isequal(columns{2}, 5) && strcmp(char(string(columns{3})), '1x'), ...
        'Launcher should use compact launcher-specific workbench columns without squeezing controls.');
end

function grid = findLauncherMainGrid(fig)
    grids = findall(fig, 'Type', 'uigridlayout');
    for k = 1:numel(grids)
        columns = grids(k).ColumnWidth;
        if numel(columns) == 3 && isequal(columns{1}, 360) && isequal(columns{2}, 5)
            grid = grids(k);
            return;
        end
    end
    error('Launcher main grid was not found.');
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

function assertLauncherFontSizes(fig)
    buttons = findall(fig, 'Type', 'uibutton');
    buttonSizes = arrayfun(@(control) control.FontSize, buttons);
    tables = findall(fig, 'Type', 'uitable');
    assert(numel(tables) == 1 && tables(1).FontSize >= 15, ...
        'Launcher app table should use the larger launcher font.');
    assert(~isempty(buttonSizes) && all(buttonSizes < tables(1).FontSize), ...
        'Launcher buttons should keep the smaller default font.');
end

function assertLauncherTableDensity(fig)
    tables = findall(fig, 'Type', 'uitable');
    assert(numel(tables) == 1, 'Launcher should draw one app table.');
    widths = tables(1).ColumnWidth;
    assert(numel(widths) == 5 && isequal(widths{1}, 150) && ...
        isequal(widths{2}, 200) && isequal(widths{3}, 90) && ...
        isequal(widths{4}, 110) && strcmp(char(string(widths{5})), 'auto'), ...
        'Launcher table should avoid over-wide family and app columns.');
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
    positions = zeros(numel(buttons), 4);
    for k = 1:numel(buttons)
        positions(k, :) = absolutePosition(buttons(k));
    end
    [~, order] = sortrows([-round(positions(:, 2), 3), round(positions(:, 1), 3)]);
    orderedTexts = texts(order);
    actual = orderedTexts(ismember(orderedTexts, string(expectedTexts)));
    assert(isequal(actual(:), string(expectedTexts(:))), ...
        'Launcher action buttons should stay together in the requested order.');
end

function assertUpdateButtonRow(fig)
    buttons = findall(fig, 'Type', 'uibutton');
    texts = string(get(buttons, 'Text'));
    mainButton = buttons(texts == "Latest");
    stableButton = buttons(texts == "Release");
    versionButton = buttons(texts == "Versions");
    assert(numel(mainButton) == 1 && numel(stableButton) == 1 && ...
        numel(versionButton) == 1, ...
        'Launcher should have one main, stable, and version-manager update button.');
    assert(isequal(mainButton.Parent, stableButton.Parent) && ...
        isequal(mainButton.Parent, versionButton.Parent), ...
        'Update buttons should live in the same compact row.');
    columns = mainButton.Parent.ColumnWidth;
    assert(numel(columns) == 4 && all(strcmp(string(columns(2:4)), "1x")), ...
        'Update row should split Latest, Release, and Versions into equal action columns.');
    assert(isequal(mainButton.Layout.Column, 2), ...
        'Latest update button should occupy the second column.');
    assert(isequal(stableButton.Layout.Column, 3), ...
        'Release update button should occupy the third column.');
    assert(isequal(versionButton.Layout.Column, 4), ...
        'Versions update button should occupy the fourth column.');
end

function pos = absolutePosition(control)
    pos = control.Position;
    parent = control.Parent;
    while ~isempty(parent) && ~isa(parent, 'matlab.ui.Figure')
        if isprop(parent, 'Position')
            parentPos = parent.Position;
            pos(1:2) = pos(1:2) + parentPos(1:2);
        end
        parent = parent.Parent;
    end
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

function assertControlText(fig, expectedText)
    actual = textValues(fig);
    assert(any(actual == string(expectedText)), ...
        'Launcher should draw "%s".', expectedText);
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
    assert(fid > 0, 'Could not create launcher test file: %s', filepath);
    cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, '%s', text);
end
