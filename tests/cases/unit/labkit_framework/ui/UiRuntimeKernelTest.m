classdef UiRuntimeKernelTest < matlab.unittest.TestCase
    methods (Test)
        function invokesLayoutCallbackAndCommitsState(testCase)
            setupLabKitTestPath();
            app = counterApplication(@incrementValue);
            runtime = app.createRuntimeForTesting();

            runtime.invokeAction("increment");

            testCase.verifyEqual(runtime.State.project.value, 1);
            testCase.verifyEqual(runtime.StatusLog, "incremented");
            testCase.verifyEqual(runtime.commitCount(), 2);
        end

        function invokesOnStartAfterFirstPresentation(testCase)
            setupLabKitTestPath();
            app = counterApplication(@incrementValue, OnStart=@markStarted);
            runtime = app.createRuntimeForTesting();

            testCase.verifyTrue(runtime.State.session.started);
            testCase.verifyEqual(runtime.commitCount(), 2);
        end

        function rollsBackStateAndPresentationOnCommitFailure(testCase)
            setupLabKitTestPath();
            app = counterApplication(@incrementValue);
            runtime = app.createRuntimeForTesting();
            before = runtime.State;
            runtime.failNextCommit();

            testCase.verifyError(@() runtime.invokeAction("increment"), ...
                "labkit:app:runtime:ActionFailed");
            testCase.verifyEqual(runtime.State, before);
            testCase.verifyEqual(runtime.commitCount(), 1);
        end

        function disposesReplacementEventAndApplicationResourcesOnce(testCase)
            setupLabKitTestPath();
            counts = containers.Map({'event', 'application'}, [0, 0]);
            app = counterApplication(@setResources);
            runtime = app.createRuntimeForTesting();
            runtime.invokeAction("increment");
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
            counts = containers.Map({'failed', 'remaining'}, [0, 0]);
            app = counterApplication(@setResources);
            runtime = app.createRuntimeForTesting();
            runtime.invokeAction("increment");

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

        function boundFieldNeedsNoCallbackOrPresenter(testCase)
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
            layout = labkit.app.layout.workbench({ ...
                labkit.app.layout.dataTable("data", ...
                    Columns=["Group", "Value"], ...
                    ColumnEditable=[true true], ...
                    OnCellEdited=@editTable, ...
                    OnCellSelectionChanged=@selectCells)});
            app = labkit.app.Definition( ...
                Entrypoint="labkit_TableProbe_app", AppId="probe.table", ...
                Title="Table probe", Family="Tests", AppVersion="1.0.0", ...
                Updated="2026-07-19", Requirements=[], Workbench=layout, ...
                CreateSession=@createTableSession, ...
                PresentWorkbench=@presentTable);
            runtime = app.createRuntimeForTesting();
            data = {"A", 1; "B", 2};

            runtime.applyTableEdit("data", labkit.app.event.TableCellEdit( ...
                RowIndex=2, ColumnIndex=2, PreviousValue=2, ...
                NewValue=3, Data=data));
            runtime.applyTableSelection("data", [1 1; 2 2]);

            testCase.verifyEqual(runtime.State.session.data, data);
            testCase.verifyEqual(runtime.State.session.cells, [1 1; 2 2]);
        end

        function sharedSourceBindingKeepsFileListsSeparatedByRole(testCase)
            setupLabKitTestPath();
            project = labkit.app.project.Schema( ...
                Version=1, Create=@createSourceProject, ...
                Validate=@validateSourceProject);
            layout = labkit.app.layout.workbench({ ...
                labkit.app.layout.fileList("reference", ...
                    Bind="project.inputs.sources", ...
                    SourceRole="reference", SourceIdPrefix="reference", ...
                    MaxFiles=1, SelectionMode="single"), ...
                labkit.app.layout.fileList("mask", ...
                    Bind="project.inputs.sources", ...
                    SourceRole="mask", SourceIdPrefix="mask", ...
                    MaxFiles=1, SelectionMode="single")});
            app = labkit.app.Definition( ...
                Entrypoint="labkit_SourceProbe_app", ...
                AppId="probe.sources", Title="Source probe", ...
                Family="Tests", AppVersion="1.0.0", ...
                Updated="2026-07-19", Requirements=[], ...
                ProjectSchema=project, Workbench=layout);
            runtime = app.createRuntimeForTesting();

            runtime.applyFileSelection("reference", "reference.png");
            runtime.applyFileSelection("mask", "mask.png");

            sources = runtime.State.project.inputs.sources;
            testCase.verifyEqual(string({sources.role}), ...
                ["reference", "mask"]);
            testCase.verifyEqual(string({sources.id}), ...
                ["reference-1", "mask-1"]);
        end

        function dispatchPreservesCellInteractionPayload(testCase)
            setupLabKitTestPath();
            interaction = labkit.app.interaction.pairedAnchors( ...
                "pairs", @storePointPairs, Axes=["left", "right"]);
            workspace = labkit.app.layout.workspace( ...
                labkit.app.layout.plotArea("preview", @drawNothing, ...
                    AxisIds=["left", "right"], ...
                    Interactions={interaction}));
            app = labkit.app.Definition( ...
                Entrypoint="labkit_PairProbe_app", AppId="probe.pairs", ...
                Title="Pair probe", Family="Tests", ...
                AppVersion="1.0.0", Updated="2026-07-19", ...
                Requirements=[], CreateSession=@createPairSession, ...
                Workbench=labkit.app.layout.workbench({}, ...
                    Workspace=workspace), ...
                PresentWorkbench=@presentPairs);
            runtime = app.createRuntimeForTesting();
            pairs = {[1 2; 3 4], [5 6; 7 8]};

            runtime.applyInteraction( ...
                "pairs", "interactionChanged", pairs);

            testCase.verifyEqual(runtime.State.session.pairs, pairs);
        end
    end
end

function app = counterApplication(onPressed, varargin)
project = labkit.app.project.Schema( ...
    Version=1, Create=@createProject, Validate=@validateProject);
app = labkit.app.Definition( ...
    "Entrypoint", "labkit_Counter_app", "AppId", "probe.counter", ...
    "Title", "Counter", "Family", "Tests", "AppVersion", "1.0.0", ...
    "Updated", "2026-07-19", "Requirements", [], ...
    "ProjectSchema", project, "CreateSession", @createSession, ...
    "Workbench", labkit.app.layout.workbench({ ...
        labkit.app.layout.field("value"), ...
        labkit.app.layout.button("increment", "Increment", onPressed)}), ...
    "PresentWorkbench", @present, varargin{:});
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
session = struct("started", false);
end

function view = present(state)
view = labkit.app.view.Snapshot().value("value", state.project.value);
end

function state = incrementValue(state, context)
state.project.value = state.project.value + 1;
context.appendStatus("incremented");
end

function state = markStarted(state, ~)
state.session.started = true;
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

function project = createSourceProject()
project = struct("inputs", struct("sources", struct([])));
end

function accepted = validateSourceProject(project)
accepted = isstruct(project) && isscalar(project) && ...
    isfield(project, "inputs") && isfield(project.inputs, "sources");
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

function session = createPairSession(~, ~)
session = struct("pairs", {{zeros(0, 2), zeros(0, 2)}});
end

function view = presentPairs(state)
view = labkit.app.view.Snapshot() ...
    .renderPlot("preview", struct()) ...
    .pairedAnchors("pairs", state.session.pairs, ImageSize=[10 10]);
end

function state = storePointPairs(state, pairs, ~)
state.session.pairs = pairs;
end

function drawNothing(~, ~)
end
