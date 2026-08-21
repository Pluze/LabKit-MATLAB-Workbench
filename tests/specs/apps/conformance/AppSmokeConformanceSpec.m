classdef AppSmokeConformanceSpec < matlab.unittest.TestCase
    %APPSMOKECONFORMANCESPEC Verify each public App's default native workflow.

    properties (TestParameter)
        App = labkittest.publicApps()
    end

    methods (Test, TestTags = {'Contract:product', 'Env:hidden-gui'})
        function materializesDefinitionAndLaunchesDefaultState(testCase, App)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            definition = feval(char(App.Package + ".definition"));
            journal = labkittest.temporarySessionJournal( ...
                definition, fullfile(folder, "default-session"));
            runtime = labkittest.createMatlabRuntime( ...
                definition, [], struct(), journal);
            cleanup = onCleanup(@() runtime.close());
            figure = runtime.figureHandle();

            testCase.verifyTrue(isgraphics(figure, "figure"));
            plan = labkittest.inspectDefinition(definition);
            nodes = plan.Nodes;
            targets = string({nodes(~arrayfun(@(node) ...
                isempty(node.Capabilities), nodes)).Id});
            testCase.verifyNotEmpty(targets);
            for target = targets
                testCase.verifyNumElements(findall(figure, "Tag", target), 1, ...
                    "Declared semantic target was not materialized exactly once: " + target);
            end
            testCase.verifyTrue(isgraphics(runtime.figureHandle(), "figure"));
            testCase.verifyFalse(runtime.StartupFailed);
            clear cleanup
        end
    end
end
