classdef AppSmokeConformanceSpec < matlab.unittest.TestCase
    %APPSMOKECONFORMANCESPEC Verify each public App materializes its declared layout.

    properties (TestParameter)
        App = labkittest.publicApps()
    end

    methods (Test, TestTags = {'Contract:product', 'Env:hidden-gui'})
        function launchesThroughTheSupportedDefinition(testCase, App)
            definition = feval(char(App.Package + ".definition"));
            runtime = labkit.app.internal.RuntimeFactory.createMatlab(definition);
            cleanup = onCleanup(@() runtime.close());
            figure = runtime.figureHandle();

            testCase.verifyTrue(isgraphics(figure, "figure"));
            plan = labkit.app.internal.DefinitionInspector.platformPlan(definition);
            nodes = plan.Nodes;
            targets = string({nodes(~arrayfun(@(node) ...
                isempty(node.Capabilities), nodes)).Id});
            testCase.verifyNotEmpty(targets);
            for target = targets
                testCase.verifyNumElements(findall(figure, "Tag", target), 1, ...
                    "Declared semantic target was not materialized exactly once: " + target);
            end
            clear cleanup
        end
    end
end
