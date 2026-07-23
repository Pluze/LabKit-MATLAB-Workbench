classdef AppSmokeConformanceSpec < matlab.unittest.TestCase
    %APPSMOKECONFORMANCESPEC Verify each public App creates its declared layout.

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
            testCase.verifyNotEmpty(findall(figure));
            clear cleanup
        end
    end
end
