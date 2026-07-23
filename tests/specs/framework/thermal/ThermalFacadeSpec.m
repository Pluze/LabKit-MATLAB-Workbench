classdef ThermalFacadeSpec < matlab.unittest.TestCase
    %THERMALFACADESPEC Specify public radiometric-image ingest behavior.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function readsRadiometricJpegWithTemperatureAndProgress(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            sourcePath = fullfile(folder, "synthetic_flir.jpg");
            fixture = writeSyntheticFlirRjpegFixture(sourcePath);
            events = {};

            records = labkit.thermal.readFiles(sourcePath, ...
                struct("progressFcn", @capture));

            testCase.verifyEqual(numel(records), 1);
            testCase.verifyEqual(records.name, "synthetic_flir.jpg");
            testCase.verifyEqual(records.format, "FLIR radiometric JPEG");
            testCase.verifyEqual(records.raw, fixture.raw);
            testCase.verifyEqual(records.units, "C");
            testCase.verifyTrue(all(isfinite(records.temperatureC), "all"));
            testCase.verifyEqual(size(records.temperatureC), size(fixture.raw));
            testCase.verifyTrue(records.metadata.temperatureConversion.available);
            testCase.verifyEqual(string(cellfun(@(event) event.stage, events, ...
                "UniformOutput", false)), ["beforeRead"; "afterRead"]);

            function capture(event)
                events{end + 1, 1} = event;
            end
        end

        function skipsUnsupportedThermalDataWhenRequested(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            thermalPath = fullfile(folder, "synthetic_flir.jpg");
            ordinaryPath = fullfile(folder, "ordinary.jpg");
            writeSyntheticFlirRjpegFixture(thermalPath);
            imwrite(uint8(120 * ones(5, 6, 3)), ordinaryPath);

            ordinary = labkit.thermal.inspectFile(ordinaryPath);
            [records, report] = labkit.thermal.readFiles( ...
                [string(ordinaryPath); string(thermalPath)], struct("SkipInvalid", true));

            testCase.verifyFalse(ordinary.isThermal);
            testCase.verifyEqual(ordinary.identifier, "labkit:thermal:FlirBlockNotFound");
            testCase.verifyEqual(numel(records), 1);
            testCase.verifyEqual(records.path, string(thermalPath));
            testCase.verifyEqual([report.requested, report.loaded, report.skipped], [2, 1, 1]);
            testCase.verifyEqual(report.failures.name, "ordinary.jpg");
        end
    end
end
