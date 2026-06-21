classdef CodeCheckReportTest < matlab.unittest.TestCase
    %CODECHECKREPORTTEST Verify the manual Code Analyzer report helper.

    methods (Test, TestTags = {'Unit'})
        function code_check_report_writes_json(testCase)
            root = setupLabKitTestPath();
            addpath(fullfile(root, "scripts"), "-end");
            testCase.addTeardown(@() rmpathIfPresent(fullfile(root, "scripts")));

            tempRoot = string(tempname);
            mkdir(tempRoot);
            testCase.addTeardown(@() removeFolderIfPresent(tempRoot));
            writeTextFile(fullfile(tempRoot, "sample.m"), ...
                "function y = sample(x)" + newline + ...
                "y = x + 1;" + newline + ...
                "end" + newline);

            report = runLabKitCodeCheckReport("Root", tempRoot);
            jsonPath = fullfile(tempRoot, "artifacts", "code-check", ...
                "matlab_code_check.json");

            testCase.verifyEqual(report.generator, "runLabKitCodeCheckReport");
            testCase.verifyEqual(report.summary.filesScanned, 1);
            testCase.verifyTrue(isfile(jsonPath));
        end
    end
end

function writeTextFile(filepath, text)
    fid = fopen(filepath, "w");
    assert(fid > 0, "Could not write test file: %s", filepath);
    cleaner = onCleanup(@() fclose(fid));
    fprintf(fid, "%s", text);
    clear cleaner;
end

function rmpathIfPresent(folder)
    paths = strsplit(path, pathsep);
    if any(strcmp(paths, folder))
        rmpath(folder);
    end
end

function removeFolderIfPresent(folder)
    if exist(folder, "dir") == 7
        rmdir(folder, "s");
    end
end
