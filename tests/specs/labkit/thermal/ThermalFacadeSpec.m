classdef ThermalFacadeSpec < matlab.unittest.TestCase
    %THERMALFACADESPEC Specify public radiometric-image ingest behavior.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function rejectsUnknownOrNonstructPublicOptions(testCase)
            calibration = struct("PlanckR1", 21106.77, "PlanckB", 1501, ...
                "PlanckF", 1, "PlanckO", -7340, "PlanckR2", 0.012545258);
            testCase.verifyError(@() labkit.thermal.rawToTemperatureC( ...
                16000, calibration, struct("Corection", "planck-basic")), ...
                "labkit:thermal:InvalidOptions");
            testCase.verifyError(@() labkit.thermal.renderImage( ...
                [1 2], "turbo"), "labkit:thermal:InvalidOptions");
        end

        function readsRadiometricJpegWithTemperatureAndProgress(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            sourcePath = fullfile(folder, "synthetic_flir.jpg");
            fixture = testfixtures.writeSyntheticFlirRjpegFixture(sourcePath);
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
            testfixtures.writeSyntheticFlirRjpegFixture(thermalPath);
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

        function validatesSuppliedEnvironmentalCalibration(testCase)
            calibration = struct("PlanckR1", 21106.77, "PlanckB", 1501, ...
                "PlanckF", 1, "PlanckO", -7340, "PlanckR2", 0.012545258);
            raw = 16000;
            [baseline, diagnostics] = labkit.thermal.rawToTemperatureC( ...
                raw, calibration);
            testCase.verifyTrue(isfinite(baseline));
            testCase.verifyTrue(diagnostics.usedDefaults);

            percentage = calibration;
            percentage.RelativeHumidity = 50;
            fraction = calibration;
            fraction.RelativeHumidity = 0.5;
            testCase.verifyEqual( ...
                labkit.thermal.rawToTemperatureC(raw, percentage), ...
                labkit.thermal.rawToTemperatureC(raw, fraction), ...
                "AbsTol", 1e-12);

            invalid = { ...
                "Emissivity", 0; ...
                "Emissivity", 1.01; ...
                "IRWindowTransmission", 0; ...
                "ObjectDistanceM", -1; ...
                "RelativeHumidity", 101};
            for k = 1:size(invalid, 1)
                candidate = calibration;
                candidate.(invalid{k, 1}) = invalid{k, 2};
                testCase.verifyError( ...
                    @() labkit.thermal.rawToTemperatureC(raw, candidate), ...
                    'labkit:thermal:InvalidCalibration');
            end
        end
    end
end
