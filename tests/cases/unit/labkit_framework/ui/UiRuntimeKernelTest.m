classdef UiRuntimeKernelTest < matlab.unittest.TestCase
    methods (Test)
        function processesCommandsAndNestedDispatchInFifoOrder(testCase)
            setupLabKitTestPath();
            increment = labkit.app.StateHandler("increment", @incrementValue);
            nested = labkit.app.StateHandler("nested", @dispatchIncrement);
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
            increment = labkit.app.StateHandler("increment", @incrementValue);
            app = counterApplication({increment}, strings(1, 0));
            runtime = app.createRuntimeForTesting();
            before = runtime.State;
            runtime.failNextCommit();

            testCase.verifyError(@() runtime.dispatch(increment, []), ...
                "labkit:app:runtime:ActionFailed");
            testCase.verifyEqual(runtime.State, before);
            testCase.verifyEqual(runtime.commitCount(), 1);
        end

        function validatesTypedPayloadBeforeCallback(testCase)
            setupLabKitTestPath();
            select = labkit.app.StateHandler( ...
                "select", @selectRows, Event="listSelection");
            app = counterApplication({select}, strings(1, 0));
            runtime = app.createRuntimeForTesting();

            testCase.verifyError(@() runtime.dispatch(select, [1 2]), ...
                "labkit:app:contract:InvalidValue");
            runtime.dispatch(select, ...
                labkit.app.event.ListSelection(Indices=[1 2]));
            testCase.verifyEqual(runtime.State.session.selection, [1 2]);
        end

        function disposesReplacementEventAndApplicationResourcesOnce(testCase)
            setupLabKitTestPath();
            counts = containers.Map( ...
                {'event', 'application'}, [0, 0]);
            resources = labkit.app.StateHandler("resources", @setResources);
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
            resources = labkit.app.StateHandler("resources", @setResources);
            app = counterApplication({resources}, "resources");
            runtime = app.createRuntimeForTesting();
            runtime.dispatch(resources, []);

            testCase.verifyError(@() runtime.close(), ...
                "labkit:app:runtime:ResourceCleanupFailed");
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
            project = labkit.app.project.Schema( ...
                Version=1, Create=@createBoundProject, ...
                Validate=@validateBoundProject);
            layout = labkit.app.layout.workbench({ ...
                labkit.app.layout.field("threshold", Kind="numeric", ...
                    Bind="project.parameters.threshold")});
            app = labkit.app.Definition( ...
                Entrypoint="labkit_BoundProbe_app", AppId="probe.bound", ...
                Title="Bound probe", Family="Tests", AppVersion="1.0.0", ...
                Updated="2026-07-19", Requirements=[], ...
                ProjectSchema=project, Workbench=layout);
            runtime = app.createRuntimeForTesting();

            runtime.applyBinding("threshold", 2.5);

            testCase.verifyEqual( ...
                runtime.State.project.parameters.threshold, 2.5);
            testCase.verifyEqual(runtime.commitCount(), 2);
            testCase.verifyError(@() labkit.app.layout.field( ...
                "bad", Bind="project.values(1)"), ...
                "labkit:app:contract:InvalidValue");
        end

        function dispatchesTypedTableEditAndCellSelection(testCase)
            setupLabKitTestPath();
            edited = labkit.app.StateHandler( ...
                "edited", @editTable, Event="tableCellEdit");
            selected = labkit.app.StateHandler( ...
                "selected", @selectCells, Event="tableCellSelection");
            layout = labkit.app.layout.workbench({ ...
                labkit.app.layout.dataTable("data", ...
                    Columns=["Group", "Value"], ...
                    ColumnEditable=[true true], ...
                    CellEdited=edited, CellSelectionChanged=selected)});
            app = labkit.app.Definition( ...
                Entrypoint="labkit_TableProbe_app", AppId="probe.table", ...
                Title="Table probe", Family="Tests", AppVersion="1.0.0", ...
                Updated="2026-07-19", Requirements=[], Workbench=layout, ...
                CreateSession=@createTableSession, BuildView=@presentTable);
            runtime = app.createRuntimeForTesting();
            data = {"A", 1; "B", 2};

            runtime.applyTableEdit("data", labkit.app.event.TableCellEdit( ...
                RowIndex=2, ColumnIndex=2, PreviousValue=2, ...
                NewValue=3, Data=data));
            runtime.applyTableSelection("data", [1 1; 2 2]);

            testCase.verifyEqual(runtime.State.session.data, data);
            testCase.verifyEqual(runtime.State.session.cells, [1 1; 2 2]);
        end
    end
end

function app = counterApplication(commands, capabilities)
    project = labkit.app.project.Schema( ...
        Version=1, Create=@createProject, Validate=@validateProject);
    app = labkit.app.Definition( ...
        Entrypoint="labkit_Counter_app", AppId="probe.counter", ...
        Title="Counter", Family="Tests", AppVersion="1.0.0", ...
        Updated="2026-07-19", Requirements=[], ProjectSchema=project, ...
        CreateSession=@createSession, ...
        Workbench=labkit.app.layout.workbench({ ...
            labkit.app.layout.field("value")}), ...
        BuildView=@present, ExtraHandlers=commands, StrictCapabilities=capabilities);
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
    view = labkit.app.view.Snapshot().value( ...
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

function session = createTableSession(~, ~)
session = struct("data", {cell(0, 2)}, "cells", zeros(0, 2));
end

function view = presentTable(state)
view = labkit.app.view.Snapshot().tableData( ...
    "data", state.session.data, Columns=["Group", "Value"], ...
    ColumnEditable=[true true]);
end

function state = editTable(state, edit, ~)
state.session.data = edit.Data;
end

function state = selectCells(state, selection, ~)
state.session.cells = selection.CellIndices;
end
