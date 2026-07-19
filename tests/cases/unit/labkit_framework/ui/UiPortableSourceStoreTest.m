classdef UiPortableSourceStoreTest < matlab.unittest.TestCase
    methods (Test, TestTags = {'Unit'})
        function createsCanonicalRecordsAndReadsPathsById(testCase)
            setupLabKitTestPath();
            runtime = sourceRuntime();
            first = runtime.sourceRecord( ...
                "first", "reference", "C:/data/first.tif", true);
            second = runtime.sourceRecord( ...
                "second", "moving", "C:/data/second.tif", false);
            records = [first; second];

            testCase.verifyEqual(string(fieldnames(first)), ...
                ["id"; "required"; "role"; "reference"]);
            testCase.verifyTrue(first.required);
            testCase.verifyFalse(second.required);
            testCase.verifyEqual(runtime.sourcePaths( ...
                records, ["second"; "missing"; "first"]), ...
                ["C:/data/second.tif"; ""; "C:/data/first.tif"]);
        end

        function upsertsAndReconcilesWithoutExposingStore(testCase)
            setupLabKitTestPath();
            runtime = sourceRuntime();
            first = runtime.sourceRecord( ...
                "first", "reference", "first.tif", true);
            replacement = runtime.sourceRecord( ...
                "first", "replacement", "replacement.tif", false);
            second = runtime.sourceRecord( ...
                "second", "moving", "second.tif", true);

            records = runtime.upsertSource(first, replacement);
            reconciled = runtime.reconcileSources( ...
                records, [second; replacement]);

            testCase.verifyEqual(records.role, "replacement");
            testCase.verifyFalse(records.required);
            testCase.verifyEqual(string({reconciled.id}).', ...
                ["second"; "first"]);
        end

        function rejectsDuplicateAndNoncanonicalRecords(testCase)
            setupLabKitTestPath();
            runtime = sourceRuntime();
            record = runtime.sourceRecord( ...
                "source", "recording", "source.csv", true);
            duplicate = record;
            duplicate.reference.extra = "not portable";

            testCase.verifyError(@() runtime.reconcileSources( ...
                [record; record], record), ...
                "labkit:app:runtime:InvalidSourceRecords");
            testCase.verifyError(@() runtime.upsertSource(record, duplicate), ...
                "labkit:app:runtime:InvalidSourceRecords");
        end
    end
end

function runtime = sourceRuntime()
app = labkit.app.Definition( ...
    Entrypoint="labkit_SourceProbe_app", AppId="probe.sources", ...
    Title="Sources", Family="Tests", AppVersion="1.0.0", ...
    Updated="2026-07-19", Requirements=[], ...
    Workbench=labkit.app.layout.workbench({}));
runtime = app.createRuntimeForTesting();
end
