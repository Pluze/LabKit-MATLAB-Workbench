classdef UiResultWriterTest < matlab.unittest.TestCase
    methods (Test, TestTags = {'Unit'})
        function writesVerifiedManifestAtomically(testCase)
            setupLabKitTestPath();
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            writeText(fullfile(folder, "summary.csv"), "value\n1\n");
            result = labkit.app.result.Package( ...
                Outputs={labkit.app.result.File( ...
                    "summary", "primary", "summary.csv", ...
                    MediaType="text/csv")}, ...
                Inputs=struct("source", "synthetic"), ...
                Parameters=struct("limit", 1), Summary=struct("rows", 1), ...
                Warnings="reviewed", ManifestName="result.json");
            runtime = testApplication().createRuntimeForTesting();

            written = runtime.writeResult(folder, result);
            manifest = jsondecode(fileread(written.Value));

            testCase.verifyFalse(written.Cancelled);
            testCase.verifyEqual(string(manifest.format), "labkit.result");
            testCase.verifyEqual(string(manifest.app.id), "test.result");
            testCase.verifyEqual(string(manifest.app.version), "1.0.0");
            testCase.verifyEqual(string(manifest.run.status), "success");
            testCase.verifyFalse(isfield(manifest, "project"));
            testCase.verifyEqual(manifest.outputs.bytes, 10);
            testCase.verifyEqual(strlength(string(manifest.outputs.sha256)), 64);
            testCase.verifyEqual(string(manifest.outputs.status), "success");
            testCase.verifyFalse(isfield(manifest, "extensions"));
            testCase.verifyFalse(isfile(string(written.Value) + ".tmp"));
        end

        function marksMissingDeclaredOutputFailedAndAggregatesPartial(testCase)
            setupLabKitTestPath();
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            writeText(fullfile(folder, "present.txt"), "present");
            result = labkit.app.result.Package( ...
                Outputs={ ...
                    labkit.app.result.File("present", "primary", "present.txt"), ...
                    labkit.app.result.File("missing", "secondary", "missing.txt")}, ...
                Inputs=struct(), Parameters=struct(), Summary=struct());
            runtime = testApplication().createRuntimeForTesting();

            written = runtime.writeResult(folder, result);
            manifest = jsondecode(fileread(written.Value));

            testCase.verifyEqual(string(manifest.run.status), "partial");
            testCase.verifyEqual(string({manifest.outputs.status}), ...
                ["success", "failed"]);
            testCase.verifyEqual(string(manifest.outputs(2).message), ...
                "Output file was not found after export.");
            testCase.verifyFalse(isfield(manifest, "project"));
        end

        function preservesFailedAndSkippedDeclarations(testCase)
            setupLabKitTestPath();
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            writeText(fullfile(folder, "present.txt"), "present");
            result = labkit.app.result.Package( ...
                Outputs={ ...
                    labkit.app.result.File("present", "primary", "present.txt"), ...
                    labkit.app.result.File("failed", "aux", "failed.txt", ...
                        Status="failed", Message="export failed"), ...
                    labkit.app.result.File("skipped", "aux", "skip.txt", ...
                        Status="skipped", Message="not requested")}, ...
                Inputs=struct(), Parameters=struct(), Summary=struct());
            runtime = testApplication().createRuntimeForTesting();

            written = runtime.writeResult(folder, result);
            manifest = jsondecode(fileread(written.Value));

            testCase.verifyEqual(string(manifest.run.status), "partial");
            testCase.verifyEqual(string({manifest.outputs.status}), ...
                ["success", "failed", "skipped"]);
            testCase.verifyEqual(manifest.outputs(2).bytes, 0);
            testCase.verifyEqual(string(manifest.outputs(3).sha256), "");
        end

        function marksAllMissingDeclaredOutputsFailed(testCase)
            setupLabKitTestPath();
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            result = labkit.app.result.Package( ...
                Outputs={labkit.app.result.File( ...
                    "missing", "primary", "missing.txt")}, ...
                Inputs=struct(), Parameters=struct(), Summary=struct());
            runtime = testApplication().createRuntimeForTesting();

            written = runtime.writeResult(folder, result);
            manifest = jsondecode(fileread(written.Value));

            testCase.verifyEqual(string(manifest.run.status), "failed");
            testCase.verifyEqual(string(manifest.outputs.status), "failed");
        end
    end
end

function app = testApplication()
    app = labkit.app.Definition( ...
        Entrypoint="labkit_ResultWriterTest_app", AppId="test.result", ...
        Title="Result writer test", Family="Tests", AppVersion="1.0.0", ...
        Updated="2026-07-19", Requirements=[], ...
        Workbench=labkit.app.layout.workbench({}));
end

function writeText(filepath, content)
    file = fopen(filepath, "w");
    cleaner = onCleanup(@() fclose(file));
    fwrite(file, content, "char");
    clear cleaner
end
