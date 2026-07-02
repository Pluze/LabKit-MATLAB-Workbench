classdef LauncherCodeAnalyzerTest < matlab.uitest.TestCase
    %LAUNCHERCODEANALYZERTEST Verify launcher Code Analyzer action.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function code_analyzer_action_uses_codeIssues(testCase)
            root = setupLabKitTestPath();
            source = fileread(fullfile(root, "labkit_launcher.m"));
            body = launcherFunctionBlock(source, ...
                '%% Section: Code Analyzer action', ...
                '%% Section: Performance profile action');

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
