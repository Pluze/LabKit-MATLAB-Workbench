classdef AppSmokeConformanceSpec < matlab.unittest.TestCase
    %APPSMOKECONFORMANCESPEC Verify each public App materializes its declared layout.

    properties (TestParameter)
        App = labkittest.publicApps()
    end

    methods (Test, TestTags = {'Contract:product', 'Env:hidden-gui'})
        function launchesThroughTheSupportedDefinition(testCase, App)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            definition = feval(char(App.Package + ".definition"));
            journal = labkittest.temporarySessionJournal(definition, folder);
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
            clear cleanup
        end

        function generatesSyntheticInputsWithoutMutatingRunningApp(testCase, App)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            definition = feval(char(App.Package + ".definition"));
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createMatlabRuntime( ...
                definition, [], struct(), ...
                journal);
            cleanup = onCleanup(@() runtime.close());
            stateBeforeGeneration = runtime.State;

            pack = runtime.generateSyntheticInputs(folder);

            testCase.verifyClass(pack, "labkit.app.synthetic.Pack");
            testCase.verifyTrue(isgraphics(runtime.figureHandle(), "figure"));
            testCase.verifyEqual(runtime.State, stateBeforeGeneration);
            testCase.verifyTrue(isfile(fullfile( ...
                folder, "synthetic-input-pack.json")));
            clear cleanup
        end

        function launchesEverySyntheticProjectNatively(testCase, App)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            definition = feval(char(App.Package + ".definition"));
            pack = labkittest.generateSyntheticInputs( ...
                definition, folder);
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createMatlabRuntime( ...
                definition, pack.InitialProject, struct(), ...
                journal);
            cleanup = onCleanup(@() runtime.close());

            testCase.verifyTrue(isgraphics(runtime.figureHandle(), "figure"));
            testCase.verifyFalse(runtime.StartupFailed);
            clear cleanup
        end
    end
end
