classdef FlirThermalPreviewSpec < matlab.unittest.TestCase
    %FLIRTHERMALPREVIEWSPEC Guard thermal detail presentation.

    methods (Test, TestTags = {'Contract:presentation', 'Env:headless'})
        function finiteReadingsProduceEveryPairwiseDifference(testCase)
            item = flir_thermal.sourceFiles.emptyItem();
            item.name = "synthetic.jpg";
            item.units = "C";
            item.hotSpot = struct("x", 1, "y", 1, "temperatureC", 30);
            item.coldSpot = struct("x", 2, "y", 2, "temperatureC", 20);
            item.manualPoint = struct( ...
                "x", 3, "y", 3, "temperatureC", 25);

            lines = string( ...
                flir_thermal.thermalPreview.presentationData.detailLines( ...
                item, 1, ""));
            differences = lines(startsWith(lines, ...
                "Temperature differences:"));

            testCase.verifySubstring(differences, ...
                "image hot - image cold = 10.00 C");
            testCase.verifySubstring(differences, ...
                "image cold - manual = -5.00 C");
        end
    end
end
