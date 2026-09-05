classdef TTestPresentationSpec < matlab.unittest.TestCase
    % Regression: category editing and explicit comparison selection stay reachable.
    methods (Test, TestTags = {'Contract:presentation', 'Env:headless'})
        function exposesCategoryEditingAlongsideDataAndResults(testCase)
            % Oracle: readers need separate category and observation tables plus
            % an explicit reference; removing any surface makes the workflow incomplete.
            plan = labkittest.inspectDefinition(ttest_wizard.definition());
            ids = string({plan.Nodes.Id});
            testCase.verifyTrue(all(ismember(["categoryTable", "referenceGroup", ...
                "renameCategories", "addCategories", "newGroupName", ...
                "dataTable", "resultTable", "resultPlot"], ids)));
            category = plan.Nodes(ids == "categoryTable");
            testCase.verifyEqual(category.Kind, "dataTable");
            project = ttest_wizard.initialData();
            state = struct("project", project, ...
                "session", ttest_wizard.createSession(project, []));
            view = ttest_wizard.workbench.present(state);
            testCase.verifyClass(view, "labkit.app.view.Snapshot");
            testCase.verifyEmpty(state.project.results.current);
        end
    end
end
