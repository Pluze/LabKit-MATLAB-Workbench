classdef TTestProjectSpec < matlab.unittest.TestCase
    %TTESTPROJECTSPEC Specify migration from the original two-vector project.

    methods (Test, TestTags = {'Contract:persistence', 'Env:headless'})
        function migratesLegacyVectorsInTheirOriginalComparisonOrder(testCase)
            spec = ttest_wizard.projectSpec();
            legacy = spec.Create();
            groupA = vector("Control", [1; 2], "source_a.csv", ["A2"; "A3"]);
            groupB = vector("Treatment", [3; 4], "source_b.csv", ["B2"; "B3"]);
            legacy.inputs = rmfield(legacy.inputs, "groups");
            legacy.inputs.vectorA = groupA;
            legacy.inputs.vectorB = groupB;
            legacy.results.current = ttest_wizard.testRun.emptyResult();

            migrated = spec.Migrate(legacy, 1);

            testCase.verifyTrue(spec.Validate(migrated));
            testCase.verifyEqual([migrated.inputs.groups.label], ["Control", "Treatment"]);
            testCase.verifyEqual(migrated.inputs.groups(1).values, [1; 2]);
            testCase.verifyEmpty(migrated.results.current);
        end
    end
end

function group = vector(label, values, source, addresses)
group = struct("label", label, "values", values, ...
    "sourceDisplayName", source, "sheet", "Table", "cellAddresses", addresses);
end
