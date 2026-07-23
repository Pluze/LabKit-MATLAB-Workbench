classdef TTestSourceTableSpec < matlab.unittest.TestCase
    %TTESTSOURCETABLESPEC Specify spreadsheet selection and CSV source values.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function extractsNumericCellsWithStableAddressesAndCounts(testCase)
            cells = {'Header', '1.5', 2; '', 3, NaN; 'note', 4, 5};
            indices = [3, 3; 1, 2; 2, 2; 1, 1; 3, 2; 2, 1];

            selected = ttest_wizard.sourceTable.extractNumericSelection(cells, indices);
            invalid = ttest_wizard.sourceTable.extractNumericSelection(cells, [2, 3]);

            testCase.verifyTrue(selected.ok);
            testCase.verifyEqual(selected.values, [1.5; 3; 4; 5], "AbsTol", 1e-12);
            testCase.verifyEqual([selected.blankCount, selected.textCount, ...
                selected.numericTextCount], [1, 1, 1]);
            testCase.verifyEqual(selected.selectedLabel, "6 selected cells");
            testCase.verifyEqual(selected.addresses, ["B1"; "B2"; "B3"; "C3"]);
            testCase.verifyFalse(invalid.ok);
            testCase.verifyEqual(invalid.invalidCount, 1);
        end

        function readsDelimitedTablesAndSuggestsLayeredGroupLabels(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            sourcePath = fullfile(folder, "synthetic.csv");
            writecell({'Group', 'Value'; 'A', 1.2; 'B', 1.8}, sourcePath);
            cells = { ...
                '22-May-2026', '', ''; 'Treatment A', '', 'Treatment B'; ...
                'Metric X', 'Metric Y', 'Metric X'; 1.1, 2.1, 3.1; 1.2, 2.2, 3.2};

            source = ttest_wizard.sourceTable.readSourceTable(sourcePath);
            label = ttest_wizard.sourceTable.suggestGroupLabel( ...
                cells, [4, 2; 5, 2], strings(0, 1));
            duplicate = ttest_wizard.sourceTable.suggestGroupLabel( ...
                cells, [4, 2; 5, 2], label);

            testCase.verifyTrue(source.ok);
            testCase.verifyEqual(source.cells{1, 1}, 'Group');
            testCase.verifyEqual(source.cells{3, 2}, 1.8, "AbsTol", 1e-12);
            testCase.verifyEqual(string(source.columnNames), ["A", "B"]);
            testCase.verifyEqual(label, "Treatment A - Metric Y");
            testCase.verifyEqual(duplicate, "Treatment A - Metric Y 2");
        end
    end
end
