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

        function clean_artifacts_has_static_safety_guards(testCase)
            root = setupLabKitTestPath();
            source = fileread(fullfile(root, "labkit_launcher.m"));
            body = launcherFunctionBlock(source, ...
                'function result = cleanGeneratedArtifacts(root)', ...
                'function tf = confirmCleanArtifacts(fig)');

            testCase.verifyFalse(isempty(strfind(body, 'targets = {')), ...
                'Clean Artifacts must keep targets as a cell list, not a char array.');
            testCase.verifyTrue(isempty(strfind(body, 'targets = [')), ...
                'Clean Artifacts must not concatenate char paths with square brackets.');
            testCase.verifyFalse(isempty(strfind(body, 'validateCleanArtifactsRoot(root)')), ...
                'Clean Artifacts must validate the project root before deleting files.');
            testCase.verifyFalse(isempty(strfind(body, ...
                'validateCleanArtifactsTarget(root, target, relativeTarget);')), ...
                'Clean Artifacts must validate each target before deleting files.');
            verifyTargetValidationBeforeDeletion(testCase, body);
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
            h.assertButtonContract(fig, {'Latest', 'Release', ...
                'Refresh App List'});
            assertNoLauncherTabs(fig);
            assertInfoContains(fig, "Use GitHub Update to repair");
            clear cleanupFigures;
            h.closeAllFigures();
            clear labkit_launcher;
            cd(originalFolder);
        end
    end
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
    drawnow;
    assert(strcmp(fig.Name, 'LabKit App Launcher'), ...
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
        'Latest', 'Release', 'Run Code Analyzer', 'Clean Artifacts', ...
        'Refresh App List'});
    assertLauncherButtonOrder(fig, {'Latest', 'Release', ...
        'Refresh App List', 'Open Selected App', 'Open Debug', ...
        'Clean Artifacts', 'Run Code Analyzer'});
    assertUpdateButtonSplit(fig);
    h.assertAnyTableColumns(fig, {'Family', 'App', 'Command'});
    assertLauncherTextAreasHaveRoom(fig);
    assertInfoContains(fig, "Project structure looks complete");
    h.invokeButton(fig, 'Refresh App List');
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
    assert(numel(widths) == 3 && isequal(widths{1}, 160) && ...
        isequal(widths{2}, 220) && strcmp(char(string(widths{3})), 'auto'), ...
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

function assertUpdateButtonSplit(fig)
    buttons = findall(fig, 'Type', 'uibutton');
    texts = string(get(buttons, 'Text'));
    mainButton = buttons(texts == "Latest");
    stableButton = buttons(texts == "Release");
    assert(numel(mainButton) == 1 && numel(stableButton) == 1, ...
        'Launcher should have one main update button and one stable update button.');
    assert(isequal(mainButton.Parent, stableButton.Parent), ...
        'Update buttons should live in the same compact row.');
    columns = mainButton.Parent.ColumnWidth;
    assert(numel(columns) == 3 && all(strcmp(string(columns), "1x")), ...
        'Update row should split label, Latest, and Release into thirds.');
    assert(isequal(mainButton.Layout.Column, 2), ...
        'Latest update button should occupy the middle third.');
    assert(isequal(stableButton.Layout.Column, 3), ...
        'Release update button should occupy the right third.');
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
