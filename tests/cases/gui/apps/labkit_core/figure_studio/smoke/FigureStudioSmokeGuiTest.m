classdef FigureStudioSmokeGuiTest < matlab.unittest.TestCase
    %FIGURESTUDIOSMOKEGUITEST Verify the bounded Figure Studio launch proof.

    methods (Test, TestTags = {'GUI', 'Smoke', 'Structural', 'RouteFeature:app-layout', 'RouteFeature:axes-presentation'})
        function launchesPreviewAndSourceControls(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            runtime = labkit.app.internal.RuntimeFactory.createMatlab( ...
                figure_studio.definition());
            runtimeCleanup = onCleanup(@() runtime.close());
            fig = runtime.figureHandle();

            h.assertStartupSucceeded(fig);
            testCase.verifyNumElements(findall(fig, "Tag", "preview.main"), 1);
            testCase.verifyNumElements(findall(fig, "Tag", "figFiles"), 1);
            testCase.verifyNumElements(findall(fig, "Tag", "sourcePanel"), 1);
            testCase.verifyNumElements(findall(fig, "Tag", "recalculateLimits"), 1);
            clear runtimeCleanup cleanup;
        end
    end
end
