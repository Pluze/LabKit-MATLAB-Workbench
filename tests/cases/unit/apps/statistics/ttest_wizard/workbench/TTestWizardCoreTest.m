classdef TTestWizardCoreTest < matlab.unittest.TestCase
    %TTESTWIZARDCORETEST Verify table extraction, t-tests, and simple CSVs.

    methods (Test, TestTags = {'Unit'})
        function spreadsheetColumnsAndSelectionsStayVisible(testCase)
            setupLabKitTestPath();
            names = ttest_wizard.sourceTable.spreadsheetColumnNames(28);
            testCase.verifyEqual(string(names([1 26 27 28])), ...
                ["A", "Z", "AA", "AB"]);

            cells = { ...
                'Header', '1.5', 2; ...
                '', 3, NaN; ...
                'note', 4, 5};
            indices = [3 3; 1 2; 2 2; 1 1; 3 2; 2 1];
            selected = ...
                ttest_wizard.sourceTable.extractNumericSelection( ...
                cells, indices);

            testCase.verifyTrue(selected.ok);
            testCase.verifyEqual(selected.values, [1.5; 3; 4; 5], ...
                'AbsTol', 1e-12);
            testCase.verifyEqual(selected.blankCount, 1);
            testCase.verifyEqual(selected.textCount, 1);
            testCase.verifyEqual(selected.numericTextCount, 1);
            testCase.verifyEqual(selected.selectedLabel, "6 selected cells");
            testCase.verifyEqual(selected.addresses, ...
                ["B1"; "B2"; "B3"; "C3"]);

            invalid = ...
                ttest_wizard.sourceTable.extractNumericSelection( ...
                cells, [2 3]);
            testCase.verifyFalse(invalid.ok);
            testCase.verifyEqual(invalid.invalidCount, 1);
        end

        function sourceReaderPreservesHeadersAsCells(testCase)
            setupLabKitTestPath();
            folder = string(tempname);
            mkdir(folder);
            cleanup = onCleanup(@() rmdir(folder, 's'));
            filepath = fullfile(folder, "synthetic.csv");
            writecell({'Group', 'Value'; 'A', 1.2; 'B', 1.8}, filepath);

            source = ttest_wizard.sourceTable.readSourceTable(filepath);

            testCase.verifyTrue(source.ok);
            testCase.verifyEqual(source.cells{1, 1}, 'Group');
            testCase.verifyEqual(source.cells{3, 2}, 1.8, 'AbsTol', 1e-12);
            testCase.verifyEqual(string(source.columnNames), ["A", "B"]);
            testCase.verifyEqual(string(source.rowNames), ["1"; "2"; "3"]);
            testCase.verifyEqual(source.sheetNames, "Table");
            clear cleanup;
        end

        function layeredHeadersSuggestBroadAndSpecificGroupNames(testCase)
            setupLabKitTestPath();
            cells = { ...
                '22-May-2026', '', ''; ...
                'Treatment A', '', 'Treatment B'; ...
                'Metric X', 'Metric Y', 'Metric X'; ...
                1.1, 2.1, 3.1; ...
                1.2, 2.2, 3.2};

            label = ttest_wizard.sourceTable.suggestGroupLabel( ...
                cells, [4 2; 5 2], strings(0, 1));
            duplicate = ttest_wizard.sourceTable.suggestGroupLabel( ...
                cells, [4 2; 5 2], label);
            secondBlock = ttest_wizard.sourceTable.suggestGroupLabel( ...
                cells, [4 3; 5 3], [label; duplicate]);

            testCase.verifyEqual(label, "Treatment A - Metric Y");
            testCase.verifyEqual(duplicate, "Treatment A - Metric Y 2");
            testCase.verifyEqual(secondBlock, "Treatment B - Metric X");
        end

        function welchMatchesIndependentReferenceValues(testCase)
            setupLabKitTestPath();
            a = [1.2 1.4 1.3 1.5];
            b = [1.8 1.7 2.0 1.9 1.6];
            options = defaultOptions();

            result = ttest_wizard.testRun.runTTest(a, b, options);

            testCase.verifyTrue(result.ok);
            testCase.verifyEqual(result.meanDifference, -0.45, ...
                'AbsTol', 1e-14);
            testCase.verifyEqual(result.tStatistic, ...
                -4.70009671080384, 'RelTol', 1e-12);
            testCase.verifyEqual(result.degreesOfFreedom, ...
                6.98076923076923, 'RelTol', 1e-12);
            testCase.verifyEqual(result.pValue, ...
                0.00222460334889963, 'RelTol', 1e-11);
            testCase.verifyEqual(result.ciLower, ...
                -0.676522028175353, 'RelTol', 1e-11);
            testCase.verifyEqual(result.ciUpper, ...
                -0.223477971824648, 'RelTol', 1e-11);
        end

        function groupFamilyComparesEachLaterGroupWithFirst(testCase)
            setupLabKitTestPath();
            groups = struct( ...
                "label", {"Reference", "Treatment 1", "Treatment 2"}, ...
                "values", { ...
                [1.2 1.4 1.3 1.5], ...
                [1.8 1.7 2.0 1.9 1.6], ...
                [1.1 1.2 1.4 1.3]});
            options = rmfield(defaultOptions(), {'labelA', 'labelB'});

            results = ttest_wizard.testRun.runGroupTTests( ...
                groups, options);

            testCase.verifySize(results, [2 1]);
            testCase.verifyEqual([results.labelA], ...
                ["Reference" "Reference"]);
            testCase.verifyEqual([results.labelB], ...
                ["Treatment 1" "Treatment 2"]);
            testCase.verifyEqual(results(1).pValue, ...
                0.00222460334889963, 'RelTol', 1e-11);
            testCase.verifyTrue( ...
                ttest_wizard.testRun.resultsMatchGroups( ...
                results, groups, options));
            groups(3).values(end) = 1.6;
            testCase.verifyFalse( ...
                ttest_wizard.testRun.resultsMatchGroups( ...
                results, groups, options));
        end

        function pooledAndPairedMatchIndependentReferenceValues(testCase)
            setupLabKitTestPath();
            options = defaultOptions();
            choices = ttest_wizard.testRun.choices();
            options.method = choices.methodLabels(2);
            pooled = ttest_wizard.testRun.runTTest( ...
                [1.2 1.4 1.3 1.5], [1.8 1.7 2.0 1.9 1.6], options);
            testCase.verifyTrue(pooled.ok);
            testCase.verifyEqual(pooled.tStatistic, ...
                -4.58257569495584, 'RelTol', 1e-12);
            testCase.verifyEqual(pooled.degreesOfFreedom, 7);
            testCase.verifyEqual(pooled.pValue, ...
                0.0025359960802581, 'RelTol', 1e-11);

            options.method = choices.methodLabels(3);
            paired = ttest_wizard.testRun.runTTest( ...
                [2.1 2.0 2.2 2.4], [2.5 2.3 2.6 2.7], options);
            testCase.verifyTrue(paired.ok);
            testCase.verifyEqual(paired.nPairs, 4);
            testCase.verifyEqual(paired.meanDifference, -0.35, ...
                'AbsTol', 1e-14);
            testCase.verifyEqual(paired.tStatistic, ...
                -12.1243556529822, 'RelTol', 1e-12);
            testCase.verifyEqual(paired.pValue, ...
                0.0012077024702717, 'RelTol', 1e-11);

            unequal = ttest_wizard.testRun.runTTest( ...
                [1 2 3], [1 2], options);
            testCase.verifyFalse(unequal.ok);
            testCase.verifyEqual(unequal.status, "unequal_pairs");
        end

        function directionalAlternativesUseAMinusBDirection(testCase)
            setupLabKitTestPath();
            a = [1.2 1.4 1.3 1.5];
            b = [1.8 1.7 2.0 1.9 1.6];
            choices = ttest_wizard.testRun.choices();
            options = defaultOptions();
            twoSided = ttest_wizard.testRun.runTTest(a, b, options);

            options.alternative = choices.alternativeLabels(2);
            greater = ttest_wizard.testRun.runTTest(a, b, options);
            testCase.verifyEqual(greater.alternativeToken, "greater");
            testCase.verifyEqual(greater.pValue, ...
                1 - twoSided.pValue / 2, 'RelTol', 1e-11);
            testCase.verifyTrue(isfinite(greater.ciLower));
            testCase.verifyEqual(greater.ciUpper, Inf);

            options.alternative = choices.alternativeLabels(3);
            less = ttest_wizard.testRun.runTTest(a, b, options);
            testCase.verifyEqual(less.alternativeToken, "less");
            testCase.verifyEqual(less.pValue, ...
                twoSided.pValue / 2, 'RelTol', 1e-11);
            testCase.verifyEqual(less.ciLower, -Inf);
            testCase.verifyTrue(isfinite(less.ciUpper));
        end

        function invalidScientificInputsReturnStableStatuses(testCase)
            setupLabKitTestPath();
            options = defaultOptions();

            tooShort = ttest_wizard.testRun.runTTest(1, [1 2], options);
            testCase.verifyFalse(tooShort.ok);
            testCase.verifyEqual(tooShort.status, "insufficient_n");

            nonfinite = ttest_wizard.testRun.runTTest( ...
                [1 NaN], [1 2], options);
            testCase.verifyFalse(nonfinite.ok);
            testCase.verifyEqual(nonfinite.status, "invalid_input");

            noVariation = ttest_wizard.testRun.runTTest( ...
                [1 1], [1 1], options);
            testCase.verifyFalse(noVariation.ok);
            testCase.verifyEqual(noVariation.status, ...
                "zero_standard_error");
        end

        function projectMigrationPreservesLegacyABOrder(testCase)
            setupLabKitTestPath();
            spec = ttest_wizard.projectSpec();
            project = spec.Create();
            groupA = struct( ...
                "label", "Control", "values", [1; 2], ...
                "sourceDisplayName", "source_a.csv", ...
                "sheet", "Table", "cellAddresses", ["A2"; "A3"]);
            groupB = struct( ...
                "label", "Treatment", "values", [3; 4], ...
                "sourceDisplayName", "source_b.csv", ...
                "sheet", "Table", "cellAddresses", ["B2"; "B3"]);
            project.inputs = rmfield(project.inputs, 'groups');
            project.inputs.vectorA = groupA;
            project.inputs.vectorB = groupB;
            project.results.current = ttest_wizard.testRun.emptyResult();

            migrated = spec.Migrate(project, 1);

            testCase.verifyTrue(spec.Validate(migrated));
            testCase.verifyEqual([migrated.inputs.groups.label], ...
                ["Control" "Treatment"]);
            testCase.verifyEqual(migrated.inputs.groups(1).values, [1; 2]);
            testCase.verifyEmpty(migrated.results.current);
        end

        function portableCsvWritersRoundTrip(testCase)
            setupLabKitTestPath();
            folder = string(tempname);
            mkdir(folder);
            cleanup = onCleanup(@() rmdir(folder, 's'));
            dataPath = fullfile(folder, "vectors.csv");
            resultPath = fullfile(folder, "result.csv");

            groups = struct( ...
                "label", {"Reference", "Treatment 1", "Treatment 2"}, ...
                "values", {[1; 2], [3; 4; 5], [6; 7]});
            ttest_wizard.sourceTable.writeGroupCsv(dataPath, groups);
            data = readcell(dataPath);
            testCase.verifyEqual(data(1, :), ...
                {'Row', 'Reference', 'Treatment 1', 'Treatment 2'});
            testCase.verifyEqual(data{4, 3}, 5);

            results = ttest_wizard.testRun.runGroupTTests( ...
                struct( ...
                "label", {"Reference", "Treatment 1", "Treatment 2"}, ...
                "values", { ...
                [1.2 1.4 1.3 1.5], ...
                [1.8 1.7 2.0 1.9 1.6], ...
                [1.1 1.2 1.4 1.3]}), ...
                rmfield(defaultOptions(), {'labelA', 'labelB'}));
            ttest_wizard.resultFiles.writeResultCsv(resultPath, results);
            saved = readcell(resultPath);
            testCase.verifyEqual(saved{1, 1}, 'Test');
            testCase.verifyEqual(saved{1, 4}, 'Reference Group');
            testCase.verifyEqual(saved{2, 21}, 'ok');
            testCase.verifyEqual(saved{3, 5}, 'Treatment 2');
            clear cleanup;
        end
    end
end

function options = defaultOptions()
    choices = ttest_wizard.testRun.choices();
    options = struct( ...
        "method", choices.methodLabels(1), ...
        "alternative", choices.alternativeLabels(1), ...
        "alpha", 0.05, ...
        "labelA", "A", ...
        "labelB", "B");
end
