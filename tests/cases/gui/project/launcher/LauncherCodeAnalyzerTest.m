classdef LauncherCodeAnalyzerTest < matlab.unittest.TestCase
    %LAUNCHERCODEANALYZERTEST Verify launcher Code Analyzer action.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function code_analyzer_action_uses_codecheck_tool(testCase)
            root = setupLabKitTestPath();
            source = fileread(fullfile(root, "labkit_launcher.m"));
            body = launcherFunctionBlock(source, ...
                '%% Section: Code Analyzer action', ...
                '%% Section: Performance profile action');

            testCase.verifyFalse(isempty(strfind(body, 'runCodecheckReport(')), ...
                'Launcher Code Analyzer action should delegate to tools/codecheck.');
            testCase.verifyTrue(isempty(strfind(body, 'codeIssues(')), ...
                'Launcher should not own the Code Analyzer scan implementation.');
            testCase.verifyTrue(isempty(strfind(body, 'checkcode(')), ...
                'Launcher Code Analyzer action should not keep the old checkcode scan loop.');
        end

        function code_analyzer_button_writes_codeIssues_report(testCase)
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
            copyfile(fullfile(root, "tools", "codecheck"), ...
                fullfile(tempRoot, "tools", "codecheck"));
            createCodeIssuesProbeApp(tempRoot);
            originalFolder = pwd;
            cd(tempRoot);
            testCase.addTeardown(@() cd(originalFolder));
            clear labkit_launcher;

            fig = labkit_launcher();
            drawnow;
            h.invokeButton(fig, 'Run Code Analyzer');
            outputRoot = fullfile(tempRoot, "artifacts", "code-check");
            jsonFiles = dir(fullfile(outputRoot, "matlab_code_issues_*.json"));
            htmlFiles = dir(fullfile(outputRoot, "matlab_code_issues_*.html"));
            testCase.verifyNumElements(jsonFiles, 1, ...
                'Run Code Analyzer should write one timestamped native codeIssues report.');
            testCase.verifyNumElements(htmlFiles, 1, ...
                'Run Code Analyzer should write one timestamped HTML Code Analyzer viewer report.');
            reportPath = fullfile(jsonFiles(1).folder, jsonFiles(1).name);
            htmlPath = fullfile(htmlFiles(1).folder, htmlFiles(1).name);
            testCase.verifyTrue(isfile(reportPath), ...
                'Run Code Analyzer should write the native codeIssues report.');
            testCase.verifyTrue(isfile(htmlPath), ...
                'Run Code Analyzer should write the HTML Code Analyzer viewer report.');
            testCase.verifyFalse(isfile(fullfile(tempRoot, "artifacts", ...
                "code-check", "matlab_code_check.json")), ...
                'Run Code Analyzer should not keep the old launcher JSON schema.');
            testCase.verifyFalse(isfile(fullfile(tempRoot, "artifacts", ...
                "code-check", "matlab_code_issues.json")), ...
                'Run Code Analyzer should not overwrite a fixed report name.');

            reportText = string(fileread(reportPath));
            htmlText = string(fileread(htmlPath));
            testCase.verifyTrue(contains(reportText, ...
                "labkit_CodeIssuesProbe_app.m"), ...
                'Report should include issues from the generated probe app.');
            testCase.verifyTrue(contains(reportText, '"CheckID"'), ...
                'Report should use the native codeIssues field names.');
            testCase.verifyTrue(contains(reportText, '"NOPRT"'), ...
                'Report should preserve codeIssues CheckID values.');
            testCase.verifyTrue(contains(htmlText, "labkit_CodeIssuesProbe_app.m"), ...
                'HTML viewer artifact should embed the generated probe report.');
            testCase.verifyTrue(contains(htmlText, 'value = 1'), ...
                'HTML viewer artifact should embed source text for selected issue files.');
            testCase.verifyTrue(contains(htmlText, '<option value="suppressed">Suppressed</option>'), ...
                'HTML viewer should expose suppressed issues as a separate filter mode.');
            clear cleanupMode cleanupFigures;
            h.closeAllFigures();
            clear labkit_launcher;
            cd(originalFolder);
        end

        function code_analyzer_report_includes_private_app_roots(testCase)
            root = setupLabKitTestPath();

            tempRoot = string(tempname);
            mkdir(tempRoot);
            testCase.addTeardown(@() removeFolderIfPresent(tempRoot));
            copyfile(fullfile(root, "tools", "codecheck"), ...
                fullfile(tempRoot, "codecheck"));
            createCodeIssuesProbeApp(tempRoot);

            privateWorkspace = string(tempname);
            mkdir(privateWorkspace);
            testCase.addTeardown(@() removeFolderIfPresent(privateWorkspace));
            createPrivateCodeIssuesProbeApp(privateWorkspace);
            writeText(fullfile(privateWorkspace, ".labkit-accept-main-guardrails"), ...
                "accept main guardrails" + newline);
            cleanupPrivateRoots = setPrivateRootsForTest(privateWorkspace);

            addpath(fullfile(tempRoot, "codecheck"));
            testCase.addTeardown(@() rmpath(fullfile(tempRoot, "codecheck")));
            report = runCodecheckReport(tempRoot, "OpenReport", false);

            reportText = string(fileread(report.jsonFile));
            htmlText = string(fileread(report.htmlFile));
            testCase.verifyTrue(contains(reportText, "labkit_PrivateCodeIssuesProbe_app.m"), ...
                "Code Analyzer report should include apps from LABKIT_PRIVATE_APP_ROOTS.");
            testCase.verifyTrue(contains(htmlText, "privateValue = 1"), ...
                "HTML viewer should embed source for private app codecheck targets.");
            clear cleanupPrivateRoots;
        end

        function code_analyzer_report_skips_private_roots_without_guardrail_sentinel(testCase)
            root = setupLabKitTestPath();

            tempRoot = string(tempname);
            mkdir(tempRoot);
            testCase.addTeardown(@() removeFolderIfPresent(tempRoot));
            copyfile(fullfile(root, "tools", "codecheck"), ...
                fullfile(tempRoot, "codecheck"));
            createCodeIssuesProbeApp(tempRoot);

            privateWorkspace = string(tempname);
            mkdir(privateWorkspace);
            testCase.addTeardown(@() removeFolderIfPresent(privateWorkspace));
            createPrivateCodeIssuesProbeApp(privateWorkspace);
            cleanupPrivateRoots = setPrivateRootsForTest(privateWorkspace);

            addpath(fullfile(tempRoot, "codecheck"));
            testCase.addTeardown(@() rmpath(fullfile(tempRoot, "codecheck")));
            report = runCodecheckReport(tempRoot, "OpenReport", false);

            reportText = string(fileread(report.jsonFile));
            testCase.verifyFalse(contains(reportText, "labkit_PrivateCodeIssuesProbe_app.m"), ...
                "Private app roots should opt in before main Code Analyzer reports scan them.");
            clear cleanupPrivateRoots;
        end

        function optional_tool_buttons_disable_when_tools_are_missing(testCase)
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
            assertButtonEnabled(fig, "Open Selected App", true);
            assertButtonEnabled(fig, "Open Debug", true);
            assertButtonEnabled(fig, "Run Code Analyzer", false);
            assertButtonEnabled(fig, "Profile Selected App", false);
            assertButtonEnabled(fig, "Package Checked", false);
            assertButtonEnabled(fig, "Checked P-code", false);

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

function createPrivateCodeIssuesProbeApp(root)
    folder = fullfile(root, "apps", "private_family", "private_probe");
    mkdir(folder);
    writeText(fullfile(folder, "labkit_PrivateCodeIssuesProbe_app.m"), sprintf([ ...
        'function varargout = labkit_PrivateCodeIssuesProbe_app(varargin)\n' ...
        '%%LABKIT_PRIVATECODEISSUESPROBE_APP Generated private codeIssues probe.\n' ...
        'privateValue = 1\n' ...
        'if nargout > 0\n' ...
        '    varargout = {privateValue};\n' ...
        'end\n' ...
        'end\n']));
end

function cleanup = setGuiTestModeForTest(mode)
    previous = getenv('LABKIT_GUI_TEST_MODE');
    setenv('LABKIT_GUI_TEST_MODE', char(mode));
    cleanup = onCleanup(@() setenv('LABKIT_GUI_TEST_MODE', previous));
end

function cleanup = setPrivateRootsForTest(folder)
    previous = getenv('LABKIT_PRIVATE_APP_ROOTS');
    setenv('LABKIT_PRIVATE_APP_ROOTS', char(folder));
    cleanup = onCleanup(@() setenv('LABKIT_PRIVATE_APP_ROOTS', previous));
end

function assertButtonEnabled(fig, label, expected)
    buttons = findall(fig, 'Type', 'uibutton');
    texts = string(get(buttons, 'Text'));
    button = buttons(texts == label);
    assert(numel(button) == 1, 'Expected one button labeled %s.', label);
    actual = string(button.Enable) == "on";
    assert(actual == expected, 'Button %s enabled state mismatch.', label);
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

function writeText(filepath, text)
    fid = fopen(filepath, 'w');
    assert(fid > 0, 'Could not create launcher Code Analyzer test file: %s', filepath);
    cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, '%s', text);
end
