classdef FlirThermalResultSpec < matlab.unittest.TestCase
    %FLIRTHERMALRESULTSPEC Specify calibrated thermal export artifacts.

    methods (Test, TestTags = {'Contract:result', 'Env:headless'})
        function exportsImageColorbarTemperatureMatrixAndManifest(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            item = thermalItem(fullfile(folder, "synthetic_flir.jpg"));

            payload = flir_thermal.resultFiles.writeOutputs(item, struct( ...
                "outputFolder", folder, "format", "PNG", "palette", "iron", ...
                "colorMapping", "Gamma", "gammaValue", 1.6, "range", []));

            testCase.verifyEqual(payload.results.status, "saved");
            testCase.verifyEqual(payload.results.colorMapping, "Gamma");
            testCase.verifyEqual(payload.results.gammaValue, 1.6, AbsTol=1e-12);
            testCase.verifyTrue(isfile(payload.results.thermalImagePath));
            testCase.verifyTrue(isfile(payload.results.colorbarPath));
            testCase.verifyTrue(isfile(payload.results.temperatureCsvPath));
            testCase.verifyTrue(isfile(payload.manifestPath));
            testCase.verifyEqual(readmatrix(payload.results.temperatureCsvPath), ...
                item.temperatureC, AbsTol=1e-12);
        end
    end
end

function item = thermalItem(path)
item = flir_thermal.sourceFiles.emptyItem();
item.path = path;
item.name = "synthetic_flir.jpg";
item.format = "FLIR radiometric JPEG";
item.temperatureC = [10 20; 40 90];
item.units = "C";
item.displayRange = [10 90];
[item.hotSpot, item.coldSpot] = ...
    flir_thermal.analysisRun.extremeTemperatureReadings(item.temperatureC);
end
