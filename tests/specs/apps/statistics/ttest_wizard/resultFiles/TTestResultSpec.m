classdef TTestResultSpec < matlab.unittest.TestCase
    %TTESTRESULTSPEC Specify portable comparison-result CSV output.

    methods (Test, TestTags = {'Contract:result', 'Env:headless'})
        function writesStableResultHeadersAndGroupLabels(testCase)
            groups = struct("label", {"Reference", "Treatment 1", "Treatment 2"}, ...
                "values", {[1.2, 1.4, 1.3, 1.5], [1.8, 1.7, 2.0, 1.9, 1.6], ...
                [1.1, 1.2, 1.4, 1.3]});
            choices = ttest_wizard.testRun.choices();
            options = struct("method", choices.methodLabels(1), ...
                "alternative", choices.alternativeLabels(1), "alpha", 0.05);
            results = ttest_wizard.testRun.runGroupTTests(groups, options);
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            destination = fullfile(folder, "results.csv");

            ttest_wizard.resultFiles.writeResultCsv(destination, results);
            saved = readcell(destination);

            testCase.verifyEqual(saved{1, 1}, 'Test');
            testCase.verifyEqual(saved{1, 4}, 'Reference Group');
            testCase.verifyEqual(saved{2, 5}, 'Treatment 1');
            testCase.verifyEqual(saved{3, 5}, 'Treatment 2');
            testCase.verifyEqual(saved{2, 21}, 'ok');
        end
    end
end
