classdef ProjectGovernanceAppTest < matlab.unittest.TestCase
    %PROJECTGOVERNANCEAPPTEST Verify project governance app helpers.

    methods (Test, TestTags = {'Unit'})
        function repoRootFindsCurrentRepository(testCase)
            root = setupLabKitTestPath();

            actual = project_governance.ops.repoRoot();

            testCase.verifyEqual(normalizePath(actual), normalizePath(root));
        end

        function previewAndDetailsReflectScaffoldState(testCase)
            setupLabKitTestPath();
            S = struct( ...
                'root', "ROOT", ...
                'family', "project", ...
                'slug', "new_tool", ...
                'entryPoint', "labkit_NewTool_app", ...
                'label', "New Tool", ...
                'lastAction', "Created app scaffold", ...
                'lastResult', "Created labkit_NewTool_app");

            rows = project_governance.view.summaryRows(S);
            lines = project_governance.view.detailLines(S);

            testCase.verifyEqual(rows(:, 1), { ...
                'App folder'; ...
                'Public command file'; ...
                'Package runner'; ...
                'UI spec'; ...
                'View helpers'; ...
                'Unit test scaffold'; ...
                'Code scan report'});
            testCase.verifyTrue(any(contains(string(rows(:, 2)), ...
                "apps/project/new_tool/labkit_NewTool_app.m")));
            testCase.verifyTrue(any(contains(string(rows(:, 2)), ...
                "tests/unit/apps/project/NewToolScaffoldTest.m")));
            testCase.verifyTrue(any(contains(string(rows(:, 2)), ...
                "artifacts/code-check/matlab_code_check.json")));
            testCase.verifyTrue(any(contains(string(lines), "App slug")));
            testCase.verifyTrue(any(contains(string(lines), "Scan Project Code")));
            testCase.verifyTrue(any(contains(string(lines), ...
                "artifacts/code-check/matlab_code_check.json")));
            testCase.verifyTrue(any(contains(string(lines), "Created app scaffold")));
        end

        function codeCheckReportWritesUnderArtifacts(testCase)
            tempRoot = tempname;
            cleaner = onCleanup(@() removeFolderIfPresent(tempRoot));
            mkdir(tempRoot);
            writeTextFile(fullfile(tempRoot, "sample.m"), [
                "function out = sample(in)"
                "out = in;"
                "end"]);

            report = project_governance.ops.runCodeCheckReport("Root", tempRoot);

            expectedReport = fullfile(tempRoot, "artifacts", "code-check", ...
                "matlab_code_check.json");
            testCase.verifyTrue(isfile(expectedReport));
            testCase.verifyFalse(isfile(fullfile(tempRoot, "matlab_code_check.json")));
            testCase.verifyEqual(report.outputs.json, ...
                "artifacts/code-check/matlab_code_check.json");
        end

        function createAppOperationBuildsOrdinaryFiles(testCase)
            root = setupLabKitTestPath();
            tempRoot = tempname;
            cleaner = onCleanup(@() removeFolderIfPresent(tempRoot));

            created = project_governance.ops.createLabKitApp( ...
                "Root", tempRoot, ...
                "Family", "project", ...
                "Slug", "governance_probe", ...
                "EntryPoint", "labkit_GovernanceProbe_app", ...
                "Label", "Governance Probe");

            appFolder = fullfile(tempRoot, "apps", "project", "governance_probe");
            testCase.verifyEqual(created.AppFolder, string(appFolder));
            testCase.verifyTrue(isfile(fullfile(appFolder, "labkit_GovernanceProbe_app.m")));
            testCase.verifyTrue(isfolder(fullfile(appFolder, "+governance_probe")));
            testCase.verifyTrue(isfile(fullfile(tempRoot, "tests", "unit", ...
                "apps", "project", "GovernanceProbeScaffoldTest.m")));
        end
    end
end

function removeFolderIfPresent(folder)
    if exist(folder, "dir") == 7
        rmdir(folder, "s");
    end
end

function writeTextFile(filepath, lines)
    fid = fopen(filepath, "w");
    assert(fid > 0, "Could not write test file: %s", filepath);
    cleaner = onCleanup(@() fclose(fid));
    for k = 1:numel(lines)
        fprintf(fid, "%s\n", char(lines(k)));
    end
    clear cleaner
end

function value = normalizePath(value)
    value = replace(string(value), '\', '/');
end
