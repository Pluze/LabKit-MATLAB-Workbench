classdef FlirThermalStateSpec < matlab.unittest.TestCase
    %FLIRTHERMALSTATESPEC Specify thermal initial runtime defaults.

    methods (Test, TestTags = {'Contract:state', 'Env:headless'})
        function createsAValidProjectWithExplicitDisplayAndExportSettings(testCase)
            project = flir_thermal.initialData();
            testCase.verifyEqual(project.parameters.colorMapping, "Linear");
            testCase.verifyEqual(project.parameters.gammaValue, 2.2);
            testCase.verifyEqual(project.parameters.exportFormat, "PNG");
        end
    end
end
