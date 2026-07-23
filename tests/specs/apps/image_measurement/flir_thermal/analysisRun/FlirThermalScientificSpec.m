classdef FlirThermalScientificSpec < matlab.unittest.TestCase
    %FLIRTHERMALSCIENTIFICSPEC Specify finite thermal readings and ROI math.

    methods (Test, TestTags = {'Contract:scientific', 'Env:headless'})
        function locatesFiniteGlobalExtremaWithoutUsingDisplaySettings(testCase)
            [hot, cold] = flir_thermal.analysisRun.extremeTemperatureReadings( ...
                [NaN 24; 18 31]);

            testCase.verifyEqual([hot.x hot.y hot.temperatureC], [2 2 31]);
            testCase.verifyEqual([cold.x cold.y cold.temperatureC], [1 2 18]);
        end

        function measuresAnInclusiveRoiWhileIgnoringNonfinitePixels(testCase)
            values = [10 NaN 30; 40 50 60; 70 80 90];
            [hot, cold, average] = flir_thermal.analysisRun.roiTemperatureMeanReading( ...
                values, [1 1], [2 2]);

            testCase.verifyEqual(hot.temperatureC, 50);
            testCase.verifyEqual(cold.temperatureC, 10);
            testCase.verifyEqual(average.temperatureC, 100/3, AbsTol=1e-12);
            testCase.verifyEqual(average.pixelCount, 3);
        end
    end
end
