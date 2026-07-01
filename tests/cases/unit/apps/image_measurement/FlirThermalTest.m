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
            testCase.verifyTrue(isfile(payload.manifestPath));
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
    end
end

function removeTempFolder(folder)
    if exist(folder, "dir") == 7
        rmdir(folder, "s");
    end
end
