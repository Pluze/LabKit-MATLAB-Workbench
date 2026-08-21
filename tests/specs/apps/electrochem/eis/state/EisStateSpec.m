classdef EisStateSpec < matlab.unittest.TestCase
    %EISSTATESPEC Specify current EIS state defaults and validation.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function defaultsNewProjectsToKilohms(testCase)
            project = eis.initialData();
            units = eis.impedanceDisplay.catalog();

            testCase.verifyEqual(project.parameters.impedanceUnit, ...
                units.choices(3));
        end
    end
end
