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
            testCase.verifyEqual(spec.Version, 3);
        end

        function migratesVersionTwoWithAnEmptyRegionExportRecord(testCase)
            spec = ecg_print.projectSpec();
            project = spec.Create();
            project.results = rmfield(project.results, "lastRegionExport");

            migrated = spec.Migrate(project, 2);

            testCase.verifyTrue(isfield(migrated.results, "lastRegionExport"));
            testCase.verifyEmpty(migrated.results.lastRegionExport);
            testCase.verifyTrue(spec.Validate(migrated));
        end

        function rejectsUnknownPeakMethodWithoutChangingSupportedProjects(testCase)
            spec = ecg_print.projectSpec();
            project = spec.Create();

            testCase.verifyTrue(spec.Validate(project));
            project.parameters.peakMethod = "unexpected";
            testCase.verifyError(@() spec.Validate(project), ...
                'ecg_print:InvalidProject');
        end
    end
end
