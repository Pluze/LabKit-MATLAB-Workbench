classdef EcgPrintProjectSpec < matlab.unittest.TestCase
    %ECGPRINTPROJECTSPEC Specify the saved ECG source migration.

    methods (Test, TestTags = {'Contract:persistence', 'Env:headless'})
        function migratesVersionOneSourceIntoTheCanonicalCollection(testCase)
            spec = ecg_print.projectSpec();
            project = spec.Create();
            expected = struct("absolutePath", "/tmp/ecg.csv");
            project.inputs.source = expected;
            project.inputs = rmfield(project.inputs, "sources");

            migrated = spec.Migrate(project, 1);

            testCase.verifyEqual(migrated.inputs.sources, expected);
            testCase.verifyFalse(isfield(migrated.inputs, "source"));
            testCase.verifyEqual(spec.Version, 2);
        end
    end
end
