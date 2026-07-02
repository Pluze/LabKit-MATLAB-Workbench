classdef ThermalFacadeTest < matlab.unittest.TestCase
    %THERMALFACADETEST Verify reusable thermal image parsing contracts.

    methods (Test, TestTags = {'Unit'})
        function thermalFacadeReadsSyntheticFlirRjpeg(testCase)
            setupLabKitTestPath();
            folder = tempname;
            mkdir(folder);
            cleanup = onCleanup(@() removeTempFolder(folder));
            sourcePath = fullfile(folder, "synthetic_flir.jpg");
            fixture = writeSyntheticFlirRjpegFixture(sourcePath);
            events = {};

            records = labkit.thermal.readFiles(sourcePath, ...
                struct("progressFcn", @captureProgress));

            testCase.verifyEqual(numel(records), 1);
            testCase.verifyEqual(records.path, string(sourcePath));
            testCase.verifyEqual(records.name, "synthetic_flir.jpg");
            testCase.verifyEqual(records.format, "FLIR radiometric JPEG");
            testCase.verifyEqual(records.raw, fixture.raw);
            testCase.verifyEqual(records.metadata.rawImageType, "PNG");
            testCase.verifyEqual(records.metadata.rawByteOrder, "native");
            testCase.verifyEqual(records.metadata.calibration.ImageWidth, 3);
            testCase.verifyEqual(records.metadata.calibration.ImageHeight, 2);
            testCase.verifyEqual(records.units, "C");
            testCase.verifyTrue(all(isfinite(records.temperatureC), "all"));
            testCase.verifyEqual(size(records.temperatureC), size(fixture.raw));

            stages = string(cellfun(@(event) event.stage, events, ...
                "UniformOutput", false));
            testCase.verifyEqual(stages(:), ["beforeRead"; "afterRead"]);

            function captureProgress(event)
                events{end + 1, 1} = event;
            end
        end

        function thermalFacadeInspectsAndSkipsNonThermalImages(testCase)
            setupLabKitTestPath();
            folder = tempname;
            mkdir(folder);
            cleanup = onCleanup(@() removeTempFolder(folder));
            thermalPath = fullfile(folder, "synthetic_flir.jpg");
            ordinaryPath = fullfile(folder, "ordinary.jpg");
            writeSyntheticFlirRjpegFixture(thermalPath);
            imwrite(uint8(120 * ones(5, 6, 3)), char(ordinaryPath));

            ordinaryInfo = labkit.thermal.inspectFile(ordinaryPath);
            [records, report] = labkit.thermal.readFiles( ...
                [string(ordinaryPath); string(thermalPath)], ...
                struct("SkipInvalid", true));

            testCase.verifyFalse(ordinaryInfo.isThermal);
            testCase.verifyTrue(ordinaryInfo.supportedExtension);
            testCase.verifyEqual(ordinaryInfo.identifier, ...
                "labkit:thermal:FlirBlockNotFound");
            testCase.verifyEqual(numel(records), 1);
            testCase.verifyEqual(records.path, string(thermalPath));
            testCase.verifyEqual(report.requested, 2);
            testCase.verifyEqual(report.loaded, 1);
            testCase.verifyEqual(report.skipped, 1);
            testCase.verifyEqual(report.failures.name, "ordinary.jpg");
        end

        function thermalFacadeRendersAndFiltersPaths(testCase)
            setupLabKitTestPath();

            filter = labkit.thermal.fileDialogFilter("IncludeAll", true);
            extensions = labkit.thermal.supportedExtensions();
            image = labkit.thermal.renderImage([20 30; 40 NaN], ...
                struct("Limits", [20 40], "Palette", "iron", "Levels", 16));

            testCase.verifyEqual(size(filter, 1), 2);
            testCase.verifyTrue(any(extensions == ".rjpg"));
            testCase.verifyTrue(labkit.thermal.isSupportedPath("sample.RJPG"));
            testCase.verifyFalse(labkit.thermal.isSupportedPath("sample.png"));
            testCase.verifyEqual(size(image), [2 2 3]);
            testCase.verifyGreaterThanOrEqual(min(image, [], "all"), 0);
            testCase.verifyLessThanOrEqual(max(image, [], "all"), 1);
            testCase.verifyError(@() labkit.thermal.renderImage([1 2], ...
                struct("Limits", [2 1])), "labkit:thermal:InvalidOptions");
        end

        function rawToTemperatureSupportsBasicAndEnvironmentModes(testCase)
            setupLabKitTestPath();
            raw = [18000 18100; 18200 18300];
            calibrationPath = [tempname '.jpg'];
            cleanup = onCleanup(@() deleteIfExists(calibrationPath));
            calibration = writeSyntheticFlirRjpegFixture(calibrationPath).calibration;

            basic = labkit.thermal.rawToTemperatureC(raw, calibration, ...
                struct("Correction", "planck-basic"));
            corrected = labkit.thermal.rawToTemperatureC(raw, calibration, ...
                struct("Correction", "environment"));

            testCase.verifyTrue(all(isfinite(basic), "all"));
            testCase.verifyTrue(all(isfinite(corrected), "all"));
            testCase.verifyEqual(size(basic), size(raw));
            testCase.verifyError(@() labkit.thermal.rawToTemperatureC(raw, ...
                rmfield(calibration, "PlanckR2")), ...
                "labkit:thermal:MissingCalibration");
        end
    end
end

function removeTempFolder(folder)
    if exist(folder, "dir") == 7
        rmdir(folder, "s");
    end
end

function deleteIfExists(filepath)
    if isfile(filepath)
        delete(filepath);
    end
end
