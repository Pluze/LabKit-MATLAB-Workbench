classdef EisProjectSpec < matlab.unittest.TestCase
    % EISPROJECTSPEC Compatibility: EIS impedance display units preserve old project meaning while new projects default to kilohms.

    methods (Test, TestTags = {'Contract:persistence', 'Env:headless'})
        function defaultsNewProjectsToKilohmsAndPreservesOldOhmProjects(testCase)
            spec = eis.projectSpec();
            units = eis.impedanceDisplay.catalog();
            current = spec.Create();
            legacy = current;
            legacy.parameters = rmfield(legacy.parameters, "impedanceUnit");
            legacy.parameters.xName = "Zreal (ohm)";
            legacy.parameters.yName = "-Zimag (ohm)";

            migrated = spec.Migrate(legacy, 1);

            testCase.verifyEqual(current.parameters.impedanceUnit, ...
                units.choices(3));
            testCase.verifyEqual(migrated.parameters.impedanceUnit, ...
                units.choices(2));
            testCase.verifyEqual(migrated.parameters.xName, "Zreal");
            testCase.verifyEqual(migrated.parameters.yName, "-Zimag");
            testCase.verifyTrue(spec.Validate(current));
            testCase.verifyTrue(spec.Validate(migrated));
        end
    end
end
