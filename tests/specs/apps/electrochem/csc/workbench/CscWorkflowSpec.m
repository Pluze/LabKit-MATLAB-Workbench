classdef CscWorkflowSpec < matlab.unittest.TestCase
    %CSCWORKFLOWSPEC Specify selected-cycle comparison and plot materialization.

    methods (Test, TestTags = {'Contract:presentation', 'Env:hidden-gui'})
        function loadsACvCtFileAndUpdatesComparisonPlots(testCase)
            source = testfixtures.dtaFixturePath( ...
                "cv_cyclic_voltammetry_pt_reference.DTA");
            runtime = labkit.app.internal.RuntimeFactory.createMatlab(csc.definition());
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();

            runtime.applyFileSelection("files", source, 1);
            tableValue = findall(figureValue, "Tag", "cycleResults");
            top = findall(figureValue, "Tag", "plotAxes.top");
            bottom = findall(figureValue, "Tag", "plotAxes.bottom");
            runtime.applyControlValue("mode", ...
                csc.analysisRun.analysisChoices().modes(2));

            testCase.verifyNumElements(runtime.State.session.cache.items, 1);
            testCase.verifyGreaterThan(size(tableValue.Data, 1), 0);
            testCase.verifyNotEmpty(top.Children);
            testCase.verifyNotEmpty(bottom.Children);
            testCase.verifyEqual(runtime.State.project.parameters.mode, ...
                csc.analysisRun.analysisChoices().modes(2));
            testCase.verifyNotEmpty(string(findall(figureValue, "Tag", "qct").Value));
            clear cleanup
        end
    end
end
