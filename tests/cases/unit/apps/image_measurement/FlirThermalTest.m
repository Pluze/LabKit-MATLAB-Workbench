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

            testCase.verifyEqual(numel(items), 1);
            testCase.verifyEqual(importReport.requested, 2);
            testCase.verifyEqual(importReport.loaded, 1);
            testCase.verifyEqual(importReport.skipped, 1);
            testCase.verifyEqual(items(1).name, "synthetic_flir.jpg");
            testCase.verifyEqual(items(1).format, "FLIR radiometric JPEG");
            testCase.verifyFalse(items(1).rangeAdjusted);
            testCase.verifyEqual(entries.status, "needs range");
            testCase.verifyEqual(items(1).rangePreset, "-20 to 120 C");
            testCase.verifyEqual(items(1).rangeControlBounds, [-20 120]);
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

            items = flir_thermal.view.rangePresetItems();
            defaultBounds = flir_thermal.view.rangeControlBounds(item, ...
                "-20 to 120 C", [0 1]);
            estimatedBounds = flir_thermal.view.rangeControlBounds(item, ...
                "Image estimate +50%", [-20 120]);
            highBounds = flir_thermal.view.rangeControlBounds(item, ...
                "-20 to 400 C", [-20 120]);
            wideBounds = flir_thermal.view.rangeControlBounds(item, ...
                "-100 to 2000 C", [-20 120]);

            testCase.verifyTrue(any(strcmp(items, 'Image estimate +50%')));
            testCase.verifyEqual(defaultBounds, [-20 120]);
            testCase.verifyEqual(estimatedBounds, [0 60]);
            testCase.verifyEqual(highBounds, [-20 400]);
            testCase.verifyEqual(wideBounds, [-100 2000]);
        end
    end
end

function removeTempFolder(folder)
    if exist(folder, "dir") == 7
        rmdir(folder, "s");
    end
end
