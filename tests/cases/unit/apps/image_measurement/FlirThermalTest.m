classdef FlirThermalTest < matlab.unittest.TestCase
    %FLIRTHERMALTEST Verify FLIR thermal app-local IO, view, and export.

    methods (Test, TestTags = {'Unit'})
        function flirThermalAppReadsSummarizesAndExports(testCase)
            setupLabKitTestPath();
            folder = tempname;
            mkdir(folder);
            cleanup = onCleanup(@() removeTempFolder(folder));
            sourcePath = fullfile(folder, "synthetic_flir.jpg");
            ordinaryPath = fullfile(folder, "ordinary.jpg");
            writeSyntheticFlirRjpegFixture(sourcePath);
            imwrite(uint8(80 * ones(4, 5, 3)), char(ordinaryPath));

            [items, importReport] = flir_thermal.io.readImages( ...
                [string(ordinaryPath); string(sourcePath)]);
            range = items(1).displayRange;
            rows = flir_thermal.view.summaryTableData(items(1), range, "turbo");
            details = flir_thermal.view.detailLines(items, 1, folder);
            entries = flir_thermal.view.filePanelEntries(items);
            payload = flir_thermal.export.writeOutputs(items, struct( ...
                "outputFolder", folder, ...
                "format", "PNG", ...
                "palette", "iron", ...
                "range", []));
            labels = flir_thermal.view.rangeControlLabels();

            testCase.verifyEqual(numel(items), 1);
            testCase.verifyEqual(importReport.requested, 2);
            testCase.verifyEqual(importReport.loaded, 1);
            testCase.verifyEqual(importReport.skipped, 1);
            testCase.verifyEqual(items(1).name, "synthetic_flir.jpg");
            testCase.verifyEqual(items(1).format, "FLIR radiometric JPEG");
            testCase.verifyFalse(items(1).rangeAdjusted);
            testCase.verifyEqual(entries.status, "needs range");
            testCase.verifyEqual(items(1).rangePreset, labels.defaultPreset);
            testCase.verifyEqual(items(1).hotSpot.temperatureC, ...
                max(items(1).temperatureC, [], "all"));
            testCase.verifyEqual(items(1).coldSpot.temperatureC, ...
                min(items(1).temperatureC, [], "all"));
            testCase.verifyLessThanOrEqual(items(1).rangeControlBounds(1), range(1));
            testCase.verifyGreaterThanOrEqual(items(1).rangeControlBounds(2), range(2));
            testCase.verifyTrue(all(isfinite(items(1).temperatureC), "all"));
            testCase.verifyGreaterThan(range(2), range(1));
            testCase.verifyTrue(any(strcmp(string(rows(:, 1)), "Measured range")));
            testCase.verifyTrue(any(strcmp(string(rows(:, 1)), "Range status")));
            testCase.verifyTrue(any(contains(string(details), "Current file: synthetic_flir.jpg")));
            testCase.verifyTrue(any(contains(string(details), "Range status: needs range")));
            testCase.verifyEqual(payload.results.status, "saved");
            testCase.verifyEqual(payload.results.rangeMin, range(1));
            testCase.verifyEqual(payload.results.rangeMax, range(2));
            testCase.verifyTrue(isfile(payload.results.thermalImagePath));
            testCase.verifyTrue(isfile(payload.results.colorbarPath));
            testCase.verifyTrue(isfile(payload.results.temperatureCsvPath));
            testCase.verifyTrue(isfile(payload.manifestPath));
            testCase.verifyTrue(ismember('imageHotTempC', ...
                payload.manifest.Properties.VariableNames));
            testCase.verifyTrue(ismember('manualPointSet', ...
                payload.manifest.Properties.VariableNames));
            testCase.verifyTrue(isnan(payload.manifest.manualTempC(1)));
            testCase.verifyEqual(payload.manifest.imageHotMinusImageColdC(1), ...
                payload.manifest.imageHotTempC(1) - ...
                payload.manifest.imageColdTempC(1), "AbsTol", 1e-10);

            exportedTemperature = readmatrix(payload.results.temperatureCsvPath);
            testCase.verifySize(exportedTemperature, size(items(1).temperatureC));
            testCase.verifyEqual(exportedTemperature, items(1).temperatureC, ...
                "AbsTol", 1e-10);

        end

        function flirThermalRawItemsFallbackAndRangeStatus(testCase)
            setupLabKitTestPath();
            item = flir_thermal.state.emptyItem();
            item.path = "raw_fixture.rjpg";
            item.name = "raw_fixture.rjpg";
            item.raw = [1 2; 3 4];
            item.temperatureC = NaN(2);
            item.units = "raw";
            item.displayRange = [1 4];

            [values, units, label] = flir_thermal.view.valueMatrix(item);
            rows = flir_thermal.view.summaryTableData(item, ...
                item.displayRange, "gray");
            entries = flir_thermal.view.filePanelEntries(item);

            testCase.verifyEqual(values, item.raw);
            testCase.verifyEqual(units, "raw");
            testCase.verifyEqual(label, "Raw thermal signal");
            testCase.verifyTrue(any(contains(string(rows(:, 2)), "1 to 4 raw")));
            testCase.verifyEqual(entries.status, "needs range");

            item.rangeAdjusted = true;
            entries = flir_thermal.view.filePanelEntries(item);
            testCase.verifyEqual(entries.status, "range set");
        end

        function flirThermalRangeControlBoundsPresets(testCase)
            setupLabKitTestPath();
            item = flir_thermal.state.emptyItem();
            item.path = "bounds_fixture.rjpg";
            item.name = "bounds_fixture.rjpg";
            item.temperatureC = [20 25; 35 40];
            item.units = "C";
            labels = flir_thermal.view.rangeControlLabels();

            items = flir_thermal.view.rangePresetItems();
            defaultBounds = flir_thermal.view.rangeControlBounds(item, ...
                labels.standardPreset, [0 1]);
            estimatedBounds = flir_thermal.view.rangeControlBounds(item, ...
                labels.estimatedPreset, [-20 120]);
            highBounds = flir_thermal.view.rangeControlBounds(item, ...
                labels.highPreset, [-20 120]);
            wideBounds = flir_thermal.view.rangeControlBounds(item, ...
                labels.widePreset, [-20 120]);

            testCase.verifyTrue(any(strcmp(items, char(labels.estimatedPreset))));
            testCase.verifyFalse(any(strcmp(items, 'Custom')));
            testCase.verifyEqual(defaultBounds, [-20 120]);
            testCase.verifyEqual(estimatedBounds, [0 60]);
            testCase.verifyEqual(highBounds, [-20 400]);
            testCase.verifyEqual(wideBounds, [-100 2000]);
        end

        function flirThermalReadingsAndManifestUseIndependentRois(testCase)
            setupLabKitTestPath();
            folder = tempname;
            mkdir(folder);
            cleanup = onCleanup(@() removeTempFolder(folder));
            item = flir_thermal.state.emptyItem();
            item.path = fullfile(folder, "readings.rjpg");
            item.name = "readings.rjpg";
            item.temperatureC = [10 20 30; 40 50 60; 70 80 90];
            item.units = "C";
            item.displayRange = [10 90];
            [item.hotSpot, item.coldSpot] = ...
                flir_thermal.ops.extremeTemperatureReadings(item.temperatureC);
            item.manualPoint = flir_thermal.ops.pointTemperatureReading( ...
                item.temperatureC, [2 2]);
            [item.roiHotSpot, ~, roiHotMean] = ...
                flir_thermal.ops.roiTemperatureMeanReading( ...
                item.temperatureC, [1 1], [2 2]);
            item.roiHotBox = boxFromRoi(roiHotMean);
            [~, item.roiColdSpot, roiColdMean] = ...
                flir_thermal.ops.roiTemperatureMeanReading( ...
                item.temperatureC, [2 2], [3 3]);
            item.roiColdBox = boxFromRoi(roiColdMean);
            [~, ~, item.roiMean] = ...
                flir_thermal.ops.roiTemperatureMeanReading( ...
                item.temperatureC, [1 3], [3 3]);

            details = flir_thermal.view.detailLines(item, 1, folder);
            payload = flir_thermal.export.writeOutputs(item, struct( ...
                "outputFolder", folder, ...
                "format", "PNG", ...
                "palette", "turbo", ...
                "range", []));
            manifest = payload.manifest;
            labels = flir_thermal.view.rangeControlLabels();

            testCase.verifyTrue(any(contains(string(details), labels.roiHotSpot)));
            testCase.verifyTrue(any(contains(string(details), "Temperature differences")));
            testCase.verifyEqual(item.roiHotSpot.temperatureC, 50);
            testCase.verifyEqual(item.roiColdSpot.temperatureC, 50);
            testCase.verifyEqual(item.roiMean.temperatureC, 80);
            testCase.verifyTrue(manifest.manualPointSet(1));
            testCase.verifyTrue(manifest.roiHotSet(1));
            testCase.verifyTrue(manifest.roiColdSet(1));
            testCase.verifyTrue(manifest.roiMeanSet(1));
            testCase.verifyEqual(manifest.manualTempC(1), 50);
            testCase.verifyEqual(manifest.roiHotTempC(1), 50);
            testCase.verifyEqual(manifest.roiColdTempC(1), 50);
            testCase.verifyEqual(manifest.roiMeanTempC(1), 80);
            testCase.verifyEqual(manifest.manualMinusRoiMeanC(1), -30);
            testCase.verifyEqual(manifest.roiHotMinusRoiMeanC(1), -30);
        end
    end
end

function box = boxFromRoi(reading)
    box = struct('x', reading.x, 'y', reading.y, ...
        'width', reading.width, 'height', reading.height, ...
        'pixelCount', reading.pixelCount);
end

function removeTempFolder(folder)
    if exist(folder, "dir") == 7
        rmdir(folder, "s");
    end
end
