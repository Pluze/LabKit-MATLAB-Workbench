classdef FlirThermalSourceSpec < matlab.unittest.TestCase
    %FLIRTHERMALSOURCESPEC Specify the transient raw thermal fallback shape.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function createsAnEmptyItemWithTheReaderFacingRangeDefaults(testCase)
            item = flir_thermal.sourceFiles.emptyItem();
            labels = flir_thermal.thermalPreview.presentationData.rangeControlLabels();

            testCase.verifyEmpty(item.temperatureC);
            testCase.verifyEqual(item.displayRange, [-20 120]);
            testCase.verifyEqual(item.rangePreset, labels.defaultPreset);
            testCase.verifyFalse(item.rangeAdjusted);
        end

        function fallsBackToRawValuesWhenTemperatureConversionIsUnavailable(testCase)
            item = flir_thermal.sourceFiles.emptyItem();
            item.path = "raw_fixture.rjpg";
            item.name = "raw_fixture.rjpg";
            item.raw = [1 2; 3 4];
            item.temperatureC = NaN(2);
            item.units = "raw";
            item.displayRange = [1 4];

            [values, units, label] = ...
                flir_thermal.thermalPreview.presentationData.valueMatrix(item);
            entries = flir_thermal.thermalPreview.presentationData.filePanelEntries(item);

            testCase.verifyEqual(values, item.raw);
            testCase.verifyEqual(units, "raw");
            testCase.verifyEqual(label, "Raw thermal signal");
            testCase.verifyEqual(entries.status, ...
                "needs range; temperature unavailable");
        end

        function marksCorrectionDefaultsAsAReaderFacingWarning(testCase)
            item = flir_thermal.sourceFiles.emptyItem();
            item.path = "defaulted_calibration.jpg";
            item.name = "defaulted_calibration.jpg";
            item.temperatureC = [20 25; 30 35];
            item.metadata.temperatureConversion = struct( ...
                "available", true, "correction", "environment", ...
                "usedDefaults", true, "defaultedFields", "Emissivity");

            entries = flir_thermal.thermalPreview.presentationData.filePanelEntries(item);
            details = flir_thermal.thermalPreview.presentationData.detailLines(item, 1, "");

            testCase.verifyEqual(entries.status, ...
                "needs range; calibration defaults used");
            testCase.verifyTrue(any(contains(string(details), ...
                "Warning: default thermal correction parameters used: Emissivity")));
        end
    end
end
