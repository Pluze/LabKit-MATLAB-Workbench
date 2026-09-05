classdef SignificanceBracketSemanticsSpec < matlab.unittest.TestCase
    % SIGNIFICANCEBRACKETSEMANTICSSPEC Regression: significance brackets must remain legend-excluded annotation lines so Figure Studio applies reference-line styling.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function provesSignificanceBracketSemantics(testCase)
            cleanup = onCleanup(@() close(findall(groot, "Type", "figure")));
            figureValue = figure(Visible="off");
            axesValue = axes(Parent=figureValue);
            groups = struct( ...
                "label", {"Reference", "Treatment A", "Treatment B"}, ...
                "values", {[10 11 12 13], [11 12 13 14], [14 15 16 17]});
            options = struct("method", "welch", ...
                "alternative", "two_sided", "alpha", 0.05);
            results = ttest_wizard.testRun.runGroupTTests(groups, options);
            % Reference moves to the last display position without changing tests.
            groups = groups([2 3 1]);
            project = ttest_wizard.initialData();
            parameters = project.parameters.plot;
            parameters.showPValue = true;
            model = struct("ready", true, "groups", groups, ...
                "results", results, "parameters", parameters, ...
                "means", arrayfun(@(group) mean(group.values), groups), ...
                "standardDeviations", ...
                arrayfun(@(group) std(group.values, 0), groups));

            ttest_wizard.resultPlot.drawComparison( ...
                struct("main", axesValue), model);

            brackets = findall(axesValue, "Type", "line");
            testCase.verifyNumElements(brackets, 2);
            testCase.verifyEqual(sortrows(vertcat(brackets.XData)), ...
                [1 1 3 3; 2 2 3 3]);
            testCase.verifyTrue(all( ...
                string({brackets.HandleVisibility}) == "off"));
            testCase.verifyTrue(all(arrayfun( ...
                @(handle) numel(handle.XData) == 4, brackets)));
            clear cleanup
        end
    end
end
