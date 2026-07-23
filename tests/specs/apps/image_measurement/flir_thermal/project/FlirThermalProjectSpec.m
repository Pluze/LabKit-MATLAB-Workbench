classdef FlirThermalProjectSpec < matlab.unittest.TestCase
    %FLIRTHERMALPROJECTSPEC Specify durable thermal project defaults.

    methods (Test, TestTags = {'Contract:persistence', 'Env:headless'})
        function createsAValidProjectWithExplicitDisplayAndExportSettings(testCase)
            spec = flir_thermal.projectSpec();
            project = spec.Create();

            testCase.verifyTrue(spec.Validate(project));
            testCase.verifyEqual(project.parameters.colorMapping, "Linear");
            testCase.verifyEqual(project.parameters.gammaValue, 2.2);
            testCase.verifyEqual(project.parameters.exportFormat, "PNG");
        end
    end
end
