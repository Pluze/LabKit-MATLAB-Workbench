classdef TTestRunSpec < matlab.unittest.TestCase
    %TTESTRUNSPEC Specify independent, pooled, paired, and grouped t tests.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function resolvesSelectionAndFreshnessWithoutChangingScientificDirection(testCase)
            % Oracle: reference B must remain vector A even when category C is first.
            groups = struct("label", {"C", "A", "B"}, ...
                "values", {[7;11], [1;3], [4;6]});
            parameters = ttest_wizard.initialData().parameters;
            parameters.referenceGroup = "B";
            parameters.excludedComparisonGroups = "C";
            selected = ttest_wizard.testRun.selectedGroups(groups, parameters);
            testCase.verifyEqual(string({selected.label}), ["B", "A"]);
            options = struct("method", "welch", "alternative", "greater", "alpha", 0.05);
            results = ttest_wizard.testRun.runGroupTTests(selected, options);
            testCase.verifyEqual(results.meanDifference, 3, AbsTol=1e-12);
            testCase.verifyTrue(ttest_wizard.testRun.resultsMatchGroups(results, selected, options));
            selected(2).values(1) = 2;
            testCase.verifyFalse(ttest_wizard.testRun.resultsMatchGroups(results, selected, options));
            parameters.referenceGroup = "Removed";
            testCase.verifyEmpty(ttest_wizard.testRun.selectedGroups(groups, parameters));
        end

        function matchesWelchReferenceStatistics(testCase)
            result = ttest_wizard.testRun.runTTest( ...
                [1.2, 1.4, 1.3, 1.5], [1.8, 1.7, 2.0, 1.9, 1.6], ...
                TTestRunSpec.options());

            testCase.verifyTrue(result.ok);
            testCase.verifyEqual(result.meanDifference, -0.45, "AbsTol", 1e-14);
            testCase.verifyEqual(result.tStatistic, -4.70009671080384, "RelTol", 1e-12);
            testCase.verifyEqual(result.degreesOfFreedom, 6.98076923076923, "RelTol", 1e-12);
            testCase.verifyEqual(result.pValue, 0.00222460334889963, "RelTol", 1e-11);
        end

        function supportsPooledPairedAndInvalidInputStatuses(testCase)
            options = TTestRunSpec.options();
            choices = ttest_wizard.testRun.choices();
            options.method = choices.methodLabels(2);
            pooled = ttest_wizard.testRun.runTTest( ...
                [1.2, 1.4, 1.3, 1.5], [1.8, 1.7, 2.0, 1.9, 1.6], options);
            options.method = choices.methodLabels(3);
            paired = ttest_wizard.testRun.runTTest( ...
                [2.1, 2.0, 2.2, 2.4], [2.5, 2.3, 2.6, 2.7], options);
            invalid = ttest_wizard.testRun.runTTest([1, 2, 3], [1, 2], options);

            testCase.verifyTrue(pooled.ok);
            testCase.verifyEqual(pooled.pValue, 0.0025359960802581, "RelTol", 1e-11);
            testCase.verifyTrue(paired.ok);
            testCase.verifyEqual([paired.nPairs, paired.meanDifference], [4, -0.35], "AbsTol", 1e-14);
            testCase.verifyFalse(invalid.ok);
            testCase.verifyEqual(invalid.status, "unequal_pairs");
        end

        function preservesDirectionalConfidenceIntervalSemantics(testCase)
            options = TTestRunSpec.options();
            choices = ttest_wizard.testRun.choices();
            twoSided = ttest_wizard.testRun.runTTest( ...
                [1.2, 1.4, 1.3, 1.5], [1.8, 1.7, 2.0, 1.9, 1.6], options);
            options.alternative = choices.alternativeLabels(2);
            greater = ttest_wizard.testRun.runTTest( ...
                [1.2, 1.4, 1.3, 1.5], [1.8, 1.7, 2.0, 1.9, 1.6], options);
            options.alternative = choices.alternativeLabels(3);
            less = ttest_wizard.testRun.runTTest( ...
                [1.2, 1.4, 1.3, 1.5], [1.8, 1.7, 2.0, 1.9, 1.6], options);

            testCase.verifyEqual(greater.alternativeToken, "greater");
            testCase.verifyEqual(greater.pValue, 1 - twoSided.pValue / 2, RelTol=1e-11);
            testCase.verifyEqual(greater.ciUpper, Inf);
            testCase.verifyEqual(less.alternativeToken, "less");
            testCase.verifyEqual(less.pValue, twoSided.pValue / 2, RelTol=1e-11);
            testCase.verifyEqual(less.ciLower, -Inf);
        end

        function distinguishesInsufficientNonfiniteAndZeroErrorInputs(testCase)
            options = TTestRunSpec.options();
            tooShort = ttest_wizard.testRun.runTTest(1, [1, 2], options);
            nonfinite = ttest_wizard.testRun.runTTest([1, NaN], [1, 2], options);
            zeroError = ttest_wizard.testRun.runTTest([1, 1], [1, 1], options);

            testCase.verifyEqual(tooShort.status, "insufficient_n");
            testCase.verifyEqual(nonfinite.status, "invalid_input");
            testCase.verifyEqual(zeroError.status, "zero_standard_error");
        end

        function comparesEveryLaterGroupWithTheReference(testCase)
            groups = struct("label", {"Reference", "Treatment 1", "Treatment 2"}, ...
                "values", {[1.2, 1.4, 1.3, 1.5], [1.8, 1.7, 2.0, 1.9, 1.6], ...
                [1.1, 1.2, 1.4, 1.3]});
            options = rmfield(TTestRunSpec.options(), {'labelA', 'labelB'});

            results = ttest_wizard.testRun.runGroupTTests(groups, options);

            testCase.verifySize(results, [2, 1]);
            testCase.verifyEqual([results.labelA], ["Reference", "Reference"]);
            testCase.verifyEqual([results.labelB], ["Treatment 1", "Treatment 2"]);
            testCase.verifyTrue(ttest_wizard.testRun.resultsMatchGroups(results, groups, options));
        end
    end

    methods (Static, Access = private)
        function options = options()
            choices = ttest_wizard.testRun.choices();
            options = struct("method", choices.methodLabels(1), ...
                "alternative", choices.alternativeLabels(1), "alpha", 0.05, ...
                "labelA", "A", "labelB", "B");
        end
    end
end
