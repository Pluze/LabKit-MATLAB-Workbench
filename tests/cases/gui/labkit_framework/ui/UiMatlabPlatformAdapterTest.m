classdef UiMatlabPlatformAdapterTest < matlab.unittest.TestCase
    methods (Test, TestTags = {'GUI', 'Structural'})
        function reconcilesChronoLikeSemanticTree(testCase)
            setupLabKitTestPath();
            helpers = guiTestHelpers();
            helpers.assertUifigureAvailable();
            app = chronoLikeApplication();
            runtime = app.createMatlabRuntime();
            cleanup = onCleanup(@() runtime.close());
            figure = runtime.figureHandle();

            testCase.verifyEqual(string(component(figure, "run").Enable), "off");
            testCase.verifyEqual(string(component(figure, "timeUnit").Value), "Time (s)");
            testCase.verifyEqual(string( ...
                component(figure, "timeUnit.label").Text), "timeUnit");
            testCase.verifyEqual(component(figure, "lineWidth").Limits, [0.5 5]);
            testCase.verifyEqual(string(component(figure, "files").Items), ...
                ["first.DTA", "second.DTA"]);
            testCase.verifyEqual(string(component(figure, "log").Value), "Loaded two files");
            testCase.verifyEqual(component(figure, "analysis").UserData.Status, "Ready");
            testCase.verifyEqual(numel(component(figure, "preview.main").Children), 1);
            clear cleanup
        end

        function preservesManualViewportAroundRenderer(testCase)
            setupLabKitTestPath();
            helpers = guiTestHelpers();
            helpers.assertUifigureAvailable();
            app = chronoLikeApplication();
            runtime = app.createMatlabRuntime();
            cleanup = onCleanup(@() runtime.close());
            ax = component(runtime.figureHandle(), "preview.main");
            ax.XLim = [-1 4];
            ax.YLim = [-2 3];
            runtime.applyBinding("lineWidth", 3);

            testCase.verifyEqual(ax.XLim, [-1 4]);
            testCase.verifyEqual(ax.YLim, [-2 3]);
            testCase.verifyEqual(string(ax.XLimMode), "manual");
            testCase.verifyEqual(string(ax.YLimMode), "manual");
            clear cleanup
        end

        function rendererFailureRestoresPreviousNativeView(testCase)
            setupLabKitTestPath();
            helpers = guiTestHelpers();
            helpers.assertUifigureAvailable();
            app = chronoLikeApplication();
            runtime = app.createMatlabRuntime();
            cleanup = onCleanup(@() runtime.close());
            ax = component(runtime.figureHandle(), "preview.main");

            testCase.verifyError( ...
                @() runtime.applyBinding("lineWidth", 4), ...
                "labkit:app:runtime:ActionFailed");

            testCase.verifyEqual(runtime.State.project.lineWidth, 1);
            testCase.verifyEqual(ax.Children(1).YData, [1 2 3]);
            clear cleanup
        end

        function nativeCallbacksUseTypedRuntimeEntrypoints(testCase)
            setupLabKitTestPath();
            helpers = guiTestHelpers();
            helpers.assertUifigureAvailable();
            runtime = chronoLikeApplication().createMatlabRuntime();
            cleanup = onCleanup(@() runtime.close());
            figure = runtime.figureHandle();

            width = component(figure, "lineWidth");
            width.Value = 2;
            width.ValueChangedFcn(width, struct());
            run = component(figure, "run");
            run.ButtonPushedFcn(run, struct());
            testCase.verifyEqual(component(figure, "data").Selection, [3 1]);
            runtime.applyFileSelection("files", ["one.DTA", "two.DTA"], [1 2]);
            files = component(figure, "files");
            files.Value = files.Items(2);
            files.ValueChangedFcn(files, struct());

            testCase.verifyEqual(runtime.State.project.lineWidth, 2);
            testCase.verifyEqual(runtime.State.project.changeCount, 1);
            testCase.verifyEqual(runtime.State.project.actionCount, 1);
            testCase.verifyEqual(runtime.State.session.sourceCount, 2);
            testCase.verifyEqual(runtime.State.session.selection.Indices, 2);
            testCase.verifyEqual( ...
                runtime.State.session.selectedSourceIds, "files-2");
            data = component(figure, "data");
            data.Data = {'A', 2; 'B', 3};
            data.CellEditCallback(data, struct( ...
                "Indices", [1 2], "PreviousData", 1, "NewData", 2));
            invokeTableSelection(data, [1 1; 2 2]);

            testCase.verifyEqual(runtime.State.project.tableEditCount, 1);
            testCase.verifyEqual(runtime.State.session.tableData, ...
                {'A', 2; 'B', 3});
            testCase.verifyEqual(runtime.State.session.tableCells, ...
                [1 1; 2 2]);
            clear cleanup
        end

        function reconcilesManagedRectangleAndDispatchesDirectCallback(testCase)
            setupLabKitTestPath();
            helpers = guiTestHelpers();
            helpers.assertUifigureAvailable();
            runtime = interactionApplication().createMatlabRuntime();
            cleanup = onCleanup(@() runtime.close());
            ax = component(runtime.figureHandle(), "preview.main");

            rectangles = findall(ax, "Type", "rectangle");
            testCase.verifyNotEmpty(rectangles);
            runtime.applyInteraction( ...
                "cropRegion", "interactionChanged", [2 3 4 5]);
            testCase.verifyEqual(runtime.State.project.crop, [2 3 4 5]);
            clear cleanup
        end
    end
end

function app = interactionApplication()
interaction = labkit.app.interaction.rectangle( ...
    "cropRegion", @changeCrop);
plot = labkit.app.layout.plotArea( ...
    "preview", @drawInteractionImage, ...
    Interactions={interaction});
app = labkit.app.Definition( ...
    Entrypoint="labkit_InteractionProbe_app", ...
    AppId="probe.interaction", Title="Interaction probe", ...
    Family="Tests", AppVersion="1.0.0", Updated="2026-07-19", ...
    Requirements=[], Workbench=labkit.app.layout.workbench({}, ...
        Workspace=labkit.app.layout.workspace(plot)), ...
    PresentWorkbench=@presentInteraction);
end

function state = changeCrop(state, position, ~)
state.project.crop = position;
end

function drawInteractionImage(axesById, ~)
imagesc(axesById.main, zeros(10));
end

function view = presentInteraction(state)
position = [1 1 3 3];
if isfield(state.project, "crop")
    position = state.project.crop;
end
view = labkit.app.view.Snapshot() ...
    .renderPlot("preview", struct()) ...
    .rectangle("cropRegion", position, ImageSize=[10 10]);
end

function app = chronoLikeApplication()
content = labkit.app.layout.group("controls", { ...
    labkit.app.layout.button("run", "Run", @runAnalysis), ...
    labkit.app.layout.field("timeUnit", Kind="choice", ...
        Value="Time (s)", Choices=["Time (s)", "Time (ms)"]), ...
    labkit.app.layout.slider("lineWidth", Value=1, Limits=[0.5 5], ...
        Bind="project.lineWidth", OnValueChanged=@lineWidthChanged), ...
    labkit.app.layout.fileList("files", Bind="project.sources", ...
        SelectionBind="session.selection", ...
        OnSelectionChanged=@fileSelectionChanged)});
dataTable = labkit.app.layout.dataTable("data", ...
    Columns=["Group", "Value"], ColumnEditable=[true true], ...
    OnCellEdited=@tableEdited, ...
    OnCellSelectionChanged=@tableSelected);
workspace = labkit.app.layout.workspace();
workspace = workspace.page("analysis", "Analysis", ...
    labkit.app.layout.plotArea("preview", @draw));
app = labkit.app.Definition(Entrypoint="labkit_ChronoProbe_app", ...
    AppId="probe.chrono", Title="Chrono probe", Family="Tests", ...
    AppVersion="1.0.0", Updated="2026-07-19", Requirements=[], ...
    ProjectSchema=labkit.app.project.Schema(Version=1, ...
        Create=@createProject, Validate=@validateProject), ...
    CreateSession=@createSession, ...
    PresentWorkbench=@presentProbe, ...
    Workbench=labkit.app.layout.workbench({content, dataTable, ...
        labkit.app.layout.logPanel("log"), ...
        labkit.app.layout.statusPanel("status")}, Workspace=workspace));
end

function view = presentProbe(state)
view = labkit.app.view.Snapshot() ...
    .enabled("run", false) ...
    .value("timeUnit", "Time (s)") ...
    .choices("timeUnit", ["Time (s)", "Time (ms)"]) ...
    .value("lineWidth", state.project.lineWidth) ...
    .limits("lineWidth", [0.5 5]) ...
    .filePaths("files", ["first.DTA", "second.DTA"]) ...
    .tableData("data", state.session.tableData, ...
        Columns=["Group", "Value"], ColumnEditable=[true true]) ...
    .tableCellSelection("data", ...
        labkit.app.event.TableCellSelection(state.session.tableCells)) ...
    .text("log", "Loaded two files") ...
    .text("status", "Ready") ...
    .workspacePage("analysis", Enabled=true, Status="Ready") ...
    .renderPlot("preview", state.project.lineWidth);
end

function project = createProject()
project = struct("lineWidth", 1, "changeCount", 0, "actionCount", 0, ...
    "tableEditCount", 0, ...
    "sources", struct([]));
end

function accepted = validateProject(project)
accepted = isstruct(project) && isscalar(project) && ...
    isfield(project, "lineWidth") && isnumeric(project.lineWidth) && ...
    isscalar(project.lineWidth) && isfinite(project.lineWidth) && ...
    isfield(project, "changeCount") && isfield(project, "actionCount") && ...
    isfield(project, "tableEditCount") && ...
    isfield(project, "sources");
end

function draw(axesById, scale)
ax = axesById.main;
cla(ax);
plot(ax, 1:3, scale * (1:3));
xlim(ax, [0 10]);
ylim(ax, [0 20]);
if scale == 4
    error("probe:RendererFailure", "Injected renderer failure.");
end
end

function state = runAnalysis(state, ~)
state.project.actionCount = state.project.actionCount + 1;
state.session.tableData = {'A', 1; 'B', 2; 'C', 3};
state.session.tableCells = [3 1];
end

function state = lineWidthChanged(state, ~, ~)
state.project.changeCount = state.project.changeCount + 1;
end

function session = createSession(project, ~)
session = struct("selection", labkit.app.event.ListSelection(), ...
    "sourceCount", numel(project.sources), ...
    "selectedSourceIds", strings(1, 0), ...
    "tableData", {{"A", 1; "B", 2}}, ...
    "tableCells", zeros(0, 2));
end

function state = fileSelectionChanged(state, selection, ~)
state.session.selectedSourceIds = selection.Ids;
end

function state = tableEdited(state, edit, ~)
state.session.tableData = edit.Data;
state.session.tableCells = zeros(0, 2);
state.project.tableEditCount = state.project.tableEditCount + 1;
end

function state = tableSelected(state, selection, ~)
state.session.tableCells = selection.CellIndices;
end

function invokeTableSelection(tableHandle, cells)
if isprop(tableHandle, "SelectionChangedFcn") && ...
        ~isempty(tableHandle.SelectionChangedFcn)
    tableHandle.SelectionChangedFcn(tableHandle, struct("Selection", cells));
else
    tableHandle.CellSelectionCallback(tableHandle, struct("Indices", cells));
end
end

function value = component(figure, tag)
value = findall(figure, "Tag", char(tag));
assert(isscalar(value), "Expected one component with Tag %s.", tag);
end
