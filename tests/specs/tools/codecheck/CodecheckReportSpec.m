classdef CodecheckReportSpec < matlab.unittest.TestCase
    %CODECHECKREPORTSPEC Guard static-analysis artifacts and progress.

    methods (Test, TestTags = {'Contract:system', 'Env:headless'})
        function reportIsNativeReadableAndProgressObservable(testCase)
            repositoryRoot = labkittest.setup();
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(repositoryRoot, "tools", "codecheck")));
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            writeText(fullfile(root, "probe.m"), [ ...
                "function value = probe()", ...
                "    value = 1;", ...
                "end"]);
            testfixtures.StateStore.set( ...
                "codecheckProgress", strings(0, 1));
            cleanup = onCleanup(@resetProgress);

            report = runCodecheckReport(root, ...
                "OpenReport", false, "ProgressFcn", @recordProgress);

            testCase.verifyEqual(exist(report.jsonFile, "file"), 2);
            testCase.verifyEqual(exist(report.htmlFile, "file"), 2);
            testCase.verifyEqual(report.fileCount, 1);
            progress = testfixtures.StateStore.get("codecheckProgress");
            testCase.verifySubstring(progress(1), "Finding MATLAB files");
            testCase.verifyTrue(any(contains(progress, ...
                "Running codeIssues on 1 MATLAB file")));
            testCase.verifySubstring(progress(end), ...
                "codeIssues report complete");
            clear cleanup
        end
    end
end

function recordProgress(message, value)
    progress = testfixtures.StateStore.get( ...
        "codecheckProgress", strings(0, 1));
    testfixtures.StateStore.set("codecheckProgress", ...
        [progress; string(message) + "|" + string(value)]);
end

function resetProgress()
    testfixtures.StateStore.reset("codecheckProgress");
end

function writeText(file, lines)
    fid = fopen(file, "w", "n", "UTF-8");
    if fid < 0
        error("LabKit:TestFixture:Write", ...
            "Could not write synthetic Code Analyzer input: %s", file);
    end
    cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, "%s\n", strjoin(lines, newline));
    clear cleanup
end
