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
    end
end
