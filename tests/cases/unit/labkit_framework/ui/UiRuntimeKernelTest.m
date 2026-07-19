classdef UiRuntimeKernelTest < matlab.unittest.TestCase
    methods (Test)
        function processesCommandsAndNestedDispatchInFifoOrder(testCase)
            setupLabKitTestPath();
            increment = labkit.ui.Command("increment", @incrementValue);
            nested = labkit.ui.Command("nested", @dispatchIncrement);
            app = counterApplication({increment, nested}, ...
                ["dispatch", "workflow"]);
            runtime = app.createRuntimeForTesting();
            runtime.dispatch(nested, []);

            testCase.verifyEqual(runtime.State.project.value, 1);
            testCase.verifyEqual(runtime.StatusLog, "queued");
            testCase.verifyEqual(runtime.commitCount(), 3);

            function state = dispatchIncrement(state, context)
                context.dispatch(increment, []);
                context.appendStatus("queued");
            end
        end

        function rollsBackStateAndPresentationOnCommitFailure(testCase)
            setupLabKitTestPath();
            increment = labkit.ui.Command("increment", @incrementValue);
            app = counterApplication({increment}, strings(1, 0));
            runtime = app.createRuntimeForTesting();
            before = runtime.State;
            runtime.failNextCommit();

            testCase.verifyError(@() runtime.dispatch(increment, []), ...
                "labkit:ui:runtime:ActionFailed");
            testCase.verifyEqual(runtime.State, before);
            testCase.verifyEqual(runtime.commitCount(), 1);
        end

        function validatesTypedPayloadBeforeCallback(testCase)
            setupLabKitTestPath();
            select = labkit.ui.Command( ...
                "select", @selectRows, Role="selection");
            app = counterApplication({select}, strings(1, 0));
            runtime = app.createRuntimeForTesting();

            testCase.verifyError(@() runtime.dispatch(select, [1 2]), ...
                "labkit:ui:contract:InvalidValue");
            runtime.dispatch(select, ...
                labkit.ui.Selection(Indices=[1 2]));
            testCase.verifyEqual(runtime.State.session.selection, [1 2]);
        end

        function disposesReplacementEventAndApplicationResourcesOnce(testCase)
            setupLabKitTestPath();
            counts = containers.Map( ...
                {'event', 'application'}, [0, 0]);
            resources = labkit.ui.Command("resources", @setResources);
            app = counterApplication({resources}, "resources");
            runtime = app.createRuntimeForTesting();
            runtime.dispatch(resources, []);
            runtime.close();
            runtime.close();

            testCase.verifyEqual(counts("event"), 2);
            testCase.verifyEqual(counts("application"), 1);

            function state = setResources(state, context)
                context.setResource("event", "temporary", 1, ...
                    @(~) incrementCount("event"));
                context.setResource("event", "temporary", 2, ...
                    @(~) incrementCount("event"));
                context.setResource("application", "reader", 3, ...
                    @(~) incrementCount("application"));
            end

            function incrementCount(name)
                counts(name) = counts(name) + 1;
            end
        end

        function cleanupFailureDoesNotSkipRemainingResources(testCase)
            setupLabKitTestPath();
            counts = containers.Map( ...
                {'failed', 'remaining'}, [0, 0]);
            resources = labkit.ui.Command("resources", @setResources);
            app = counterApplication({resources}, "resources");
            runtime = app.createRuntimeForTesting();
            runtime.dispatch(resources, []);

            testCase.verifyError(@() runtime.close(), ...
                "labkit:ui:runtime:ResourceCleanupFailed");
            testCase.verifyEqual(counts("failed"), 1);
            testCase.verifyEqual(counts("remaining"), 1);

            function state = setResources(state, context)
                context.setResource("application", "failure", 1, ...
                    @(~) failCleanup());
                context.setResource("application", "remaining", 2, ...
                    @(~) incrementCount("remaining"));
            end

            function failCleanup()
                incrementCount("failed");
                error("labkit:test:InjectedCleanupFailure", ...
                    "Injected cleanup failure.");
            end

            function incrementCount(name)
                counts(name) = counts(name) + 1;
            end
        end

        function boundFieldNeedsNoCommandOrPresenter(testCase)
            setupLabKitTestPath();
            project = labkit.ui.ProjectContract( ...
                Version=1, Create=@createBoundProject, ...
                Validate=@validateBoundProject);
            layout = labkit.ui.Layout.workbench({ ...
                labkit.ui.Layout.field("threshold", Kind="numeric", ...
                    Bind="project.parameters.threshold")});
            app = labkit.ui.Application( ...
                Command="labkit_BoundProbe_app", Id="probe.bound", ...
                Title="Bound probe", Family="Tests", AppVersion="1.0.0", ...
                Updated="2026-07-19", Requirements=[], ...
                Project=project, Layout=layout);
            runtime = app.createRuntimeForTesting();

            runtime.applyBinding("threshold", 2.5);

            testCase.verifyEqual( ...
                runtime.State.project.parameters.threshold, 2.5);
            testCase.verifyEqual(runtime.commitCount(), 2);
            testCase.verifyError(@() labkit.ui.Layout.field( ...
                "bad", Bind="project.values(1)"), ...
                "labkit:ui:contract:InvalidValue");
        end
    end
end

function app = counterApplication(commands, capabilities)
    project = labkit.ui.ProjectContract( ...
        Version=1, Create=@createProject, Validate=@validateProject);
    app = labkit.ui.Application( ...
        Command="labkit_Counter_app", Id="probe.counter", ...
        Title="Counter", Family="Tests", AppVersion="1.0.0", ...
        Updated="2026-07-19", Requirements=[], Project=project, ...
        Session=@createSession, ...
        Layout=labkit.ui.Layout.workbench({ ...
            labkit.ui.Layout.field("value")}), ...
        Present=@present, ExtraCommands=commands, Capabilities=capabilities);
end

function project = createProject()
    project = struct("value", 0);
end

function accepted = validateProject(project)
    accepted = isstruct(project) && isscalar(project) && ...
        isfield(project, "value") && isnumeric(project.value) && ...
        isscalar(project.value) && isfinite(project.value);
end

function session = createSession(~, ~)
    session = struct();
end

function view = present(state)
    view = labkit.ui.Presentation().value( ...
        "value", state.project.value);
end

function state = incrementValue(state, ~)
    state.project.value = state.project.value + 1;
end

function state = selectRows(state, selection, ~)
    state.session.selection = selection.Indices;
end

function project = createBoundProject()
    project = struct("parameters", struct("threshold", 1));
end

function accepted = validateBoundProject(project)
    accepted = isstruct(project) && isscalar(project) && ...
        isfield(project, "parameters") && ...
        isstruct(project.parameters) && isscalar(project.parameters) && ...
        isfield(project.parameters, "threshold") && ...
        isnumeric(project.parameters.threshold) && ...
        isscalar(project.parameters.threshold) && ...
        isfinite(project.parameters.threshold);
end
