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
                ["01 first.DTA [ready]", ...
                 "02 second.DTA [needs review]"]);
            testCase.verifyEqual( ...
                component(figure, "files").UserData.Paths, ...
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

        function replacesChoicesWhenCurrentValueDisappears(testCase)
            setupLabKitTestPath();
            helpers = guiTestHelpers();
            helpers.assertUifigureAvailable();
            runtime = chronoLikeApplication().createMatlabRuntime();
            cleanup = onCleanup(@() runtime.close());
            figure = runtime.figureHandle();

            runtime.applyBinding("dynamicChoice", "ECG");

            choice = component(figure, "dynamicChoice");
            testCase.verifyEqual(string(choice.Items), "ECG");
            testCase.verifyEqual(string(choice.Value), "ECG");
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

        function enforcesSharedWorkbenchVisualPolicy(testCase)
            setupLabKitTestPath();
            helpers = guiTestHelpers();
            helpers.assertUifigureAvailable();
            runtime = visualPolicyApplication().createMatlabRuntime();
            cleanup = onCleanup(@() runtime.close());
            figure = runtime.figureHandle();
            testCase.verifyEmpty(findall(figure, ...
                "Tag", "labkitAppStartupStatus"));
            testCase.verifyFalse(isappdata(figure, "labkitAppBusy"));
            runtime.showFigure();
            figure.Visible = "off";
            testCase.verifyEqual(string(figure.Name), ...
                "Visual policy probe v1.0.0 (2026-07-19)");

            workbench = component(figure, "labkitAppWorkbenchGrid");
            testCase.verifyEqual(workbench.ColumnWidth{1}, 420);
            testCase.verifyEqual(workbench.ColumnWidth{2}, 6);
            testCase.verifyEqual(numel(findall(figure, ...
                "Tag", "labkitAppColumnResize")), 1);
            testCase.verifyGreaterThanOrEqual(numel(findall(figure, ...
                "Tag", "labkitAppRowResize")), 3);

            tabLayout = component(figure, "mainTab.layout");
            testCase.verifyEqual(string(tabLayout.Scrollable), "on");
            fieldLayout = component(figure, "visualChoice.layout");
            choice = component(figure, "visualChoice");
            testCase.verifyEqual(choice.Layout.Row, 1);
            testCase.verifyEqual(fieldLayout.Layout.Row, 2);
            gain = component(figure, "visualGain");
            testCase.verifyTrue(contains(string(class(gain)), "Spinner"));
            testCase.verifyEqual(gain.Step, 0.1);
            testCase.verifyEqual(string(gain.ValueDisplayFormat), "%.2f");
            testCase.verifyEqual(numel(findall(figure, ...
                "Tag", "visualGain.slider")), 1);
            rangeStart = component(figure, "visualRange");
            rangeEnd = component(figure, "visualRange.end");
            testCase.verifyTrue(contains(string(class(rangeStart)), ...
                "NumericEditField"));
            testCase.verifyTrue(contains(string(class(rangeEnd)), ...
                "NumericEditField"));
            autoFirst = component(figure, "visualAutoFirst");
            autoSecond = component(figure, "visualAutoSecond");
            autoThird = component(figure, "visualAutoThird");
            visualRun = component(figure, "visualRun");
            visualReset = component(figure, "visualReset");
            titledGroup = component(figure, "visualButtons");
            drawnow;
            testCase.verifyEqual(string(titledGroup.Title), "Commands");
            testCase.verifyEqual(string(titledGroup.BorderType), "line");
            testCase.verifyGreaterThanOrEqual(visualRun.Position(4), 22);
            testCase.verifyGreaterThanOrEqual(visualReset.Position(4), 22);
            testCase.verifyEqual(string(visualRun.Text), "Run");
            testCase.verifyEqual(string(visualReset.Text), "Reset");
            testCase.verifyEqual(autoFirst.Layout.Column, 1);
            testCase.verifyEqual(autoSecond.Layout.Column, 2);
            testCase.verifyEqual(autoThird.Layout.Column, [1 2]);
            testCase.verifyNotEmpty(autoThird.Tooltip);

            testCase.verifyEqual(numel(findall(figure, ...
                "Tag", "visualFile.choose")), 1);
            testCase.verifyEqual(numel(findall(figure, ...
                "Tag", "visualFile.status")), 1);
            testCase.verifyEqual(string(component( ...
                figure, "visualFile.status").Value), "Image loaded");
            testCase.verifyEmpty(findall(figure, ...
                "Tag", "visualFile.remove"));
            testCase.verifyEqual(numel(findall(figure, ...
                "Tag", "visualFiles.folder")), 1);
            testCase.verifyEqual(numel(findall(figure, ...
                "Tag", "visualFiles.recursiveFolder")), 1);
            testCase.verifyEqual(numel(findall(figure, ...
                "Tag", "visualFiles.status")), 1);
            testCase.verifyEqual(string(component( ...
                figure, "visualFiles.status").Value), ...
                "Two files queued");

            logPanel = component(figure, "visualLog.panel");
            testCase.verifyEqual(string(logPanel.Title), "Log");
            testCase.verifyEqual(string(logPanel.BorderType), "line");
            logTabLayout = component(figure, "logTab.layout");
            logSectionLayout = component(figure, ...
                "visualLogSection.layout");
            testCase.verifyEqual(string(logTabLayout.RowHeight{1}), "1x");
            testCase.verifyEqual(string(logTabLayout.Scrollable), "off");
            testCase.verifyEqual(string( ...
                logSectionLayout.RowHeight{1}), "1x");
            follow = component(figure, "visualLog.follow");
            testCase.verifyEqual(string(follow.Text), "Pause auto-scroll");
            testCase.verifyEqual(string(component( ...
                figure, "visualLog").Value), "Ready.");
            logSection = component(figure, "visualLog.panel").Parent;
            testCase.verifyGreaterThan(logSection.Position(4), ...
                0.75 * logTabLayout.Position(4));
            testCase.verifyEqual(string(component( ...
                figure, "applicationUsage").Value), ...
                ["Choose inputs"; "Run analysis"]);

            mode = component(figure, "visualPlot.viewMode");
            testCase.verifyEqual(string(mode.Value), "Second");
            leftAxes = component(figure, "visualPlot.left");
            rightAxes = component(figure, "visualPlot.right");
            testCase.verifyNotEmpty(figure.WindowScrollWheelFcn, ...
                "Declared plot navigation must work without an ROI editor.");
            testCase.verifyEqual(leftAxes.Layout.Row, 1);
            testCase.verifyEqual(leftAxes.Layout.Column, 1);
            testCase.verifyEqual(rightAxes.Layout.Row, 1);
            testCase.verifyEqual(rightAxes.Layout.Column, 2);
            testCase.verifyEqual(string(leftAxes.Title.String), "Left");
            testCase.verifyEqual(string(rightAxes.XLabel.String), "Time");
            testCase.verifyEqual(string(getappdata(rightAxes, ...
                "labkitPreviewScrollZoomAxes")), "x");

            menuTags = ["labkitAppUtilityPlotMenu", ...
                "labkitAppUtilityScreenshot"];
            for tag = menuTags
                testCase.verifyEqual(numel(findall( ...
                    figure, "Tag", tag)), 1);
            end
            figure.CloseRequestFcn(figure, []);
            testCase.verifyTrue(isvalid(figure));
            testCase.verifyEqual(numel(findall(figure, ...
                "Tag", "labkitAppClosePrompt")), 1);
            clear cleanup
        end

        function updatesVersionedDocumentTitleAcrossSaveAndEdit(testCase)
            setupLabKitTestPath();
            helpers = guiTestHelpers();
            helpers.assertUifigureAvailable();
            runtime = chronoLikeApplication().createMatlabRuntime();
            cleanup = onCleanup(@() runtime.close());
            filepath = string(tempname) + ".mat";
            cleanupFile = onCleanup(@() deleteIfPresent(filepath));
            figure = runtime.figureHandle();
            runtime.showFigure();
            figure.Visible = "off";

            testCase.verifyEqual(string(figure.Name), ...
                "Chrono probe v1.0.0 (2026-07-19) *");
            runtime.saveProject(runtime.State, filepath);
            testCase.verifyEqual(string(figure.Name), ...
                "Chrono probe v1.0.0 (2026-07-19)");
            runtime.applyBinding("lineWidth", 2);
            testCase.verifyEqual(string(figure.Name), ...
                "Chrono probe v1.0.0 (2026-07-19) *");
            clear cleanupFile cleanup
        end
    end
end

function app = visualPolicyApplication()
main = labkit.app.layout.tab("mainTab", "Main", { ...
    labkit.app.layout.section("visualInputs", "Inputs", { ...
        labkit.app.layout.fileList("visualFile", Label="Image", ...
            SelectionMode="single", MaxFiles=1), ...
        labkit.app.layout.field("visualChoice", Label="Mode:", ...
            Kind="choice", Choices=["One", "Two"]), ...
        labkit.app.layout.slider("visualGain", Label="Gain:", ...
            Limits=[-1 1], Step=0.1, ValueDisplayFormat="%.2f"), ...
        labkit.app.layout.rangeField("visualRange", Label="Range:", ...
            Value=[0.2 0.8], Limits=[0 1]), ...
        labkit.app.layout.field("visualResult", Label="Result:", ...
            Kind="readonly", Value="-")}), ...
    labkit.app.layout.section("visualActions", "Actions", { ...
        labkit.app.layout.group("visualButtons", { ...
            labkit.app.layout.button("visualRun", "Run", @noOp), ...
            labkit.app.layout.button("visualReset", "Reset", @noOp)}, ...
            Layout="horizontal", Title="Commands"), ...
        labkit.app.layout.group("visualAutoButtons", { ...
            labkit.app.layout.button("visualAutoFirst", "First", @noOp), ...
            labkit.app.layout.button("visualAutoSecond", "Second", @noOp), ...
            labkit.app.layout.button("visualAutoThird", ...
                "Third action", @noOp)})}), ...
    labkit.app.layout.section("visualFileBatch", "Batch", { ...
        labkit.app.layout.fileList("visualFiles", ...
            Label="Files", SelectionMode="multiple")})});
log = labkit.app.layout.tab("logTab", "Log", { ...
    labkit.app.layout.section("visualLogSection", "Log", { ...
        labkit.app.layout.logPanel("visualLog", Title="Log")})});
workspace = labkit.app.layout.workspace( ...
    labkit.app.layout.plotArea("visualPlot", @drawVisualPolicy, ...
        Title="Plots", Layout="pair", AxisIds=["left", "right"], ...
        AxisTitles=["Left", "Right"], XLabels=["", "Time"], ...
        YLabels=["Value", ""], ColumnWidths={120, '1x'}, ...
        ScrollZoomAxes=["xy", "x"], ViewModes=["First", "Second"], ...
        OnValueChanged=@changeVisualMode));
app = labkit.app.Definition( ...
    Entrypoint="labkit_VisualPolicyProbe_app", ...
    AppId="probe.visual-policy", Title="Visual policy probe", ...
    Family="Tests", AppVersion="1.0.0", Updated="2026-07-19", ...
    Requirements=[], Workbench=labkit.app.layout.workbench( ...
        {main, log}, Workspace=workspace, ...
        Usage=["Choose inputs", "Run analysis"]), ...
    PresentWorkbench=@presentVisualPolicy);
end

function state = noOp(state, ~)
end

function state = changeVisualMode(state, value, ~)
state.session.visualMode = value;
end

function drawVisualPolicy(axesById, ~)
plot(axesById.left, 1:2, 1:2);
plot(axesById.right, 1:2, 2:-1:1);
end

function view = presentVisualPolicy(~)
view = labkit.app.view.Snapshot() ...
    .text("visualFile", "Image loaded") ...
    .text("visualFiles", "Two files queued") ...
    .value("visualPlot", "Second") ...
    .renderPlot("visualPlot", struct());
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
    labkit.app.layout.field("dynamicChoice", Kind="choice", ...
        Choices="(none)", Bind="project.dynamicChoice"), ...
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
    .choices("dynamicChoice", dynamicChoices(state.project.dynamicChoice)) ...
    .value("dynamicChoice", state.project.dynamicChoice) ...
    .value("lineWidth", state.project.lineWidth) ...
    .limits("lineWidth", [0.5 5]) ...
    .filePaths("files", ["first.DTA", "second.DTA"]) ...
    .fileItemStatuses("files", ["ready", "needs review"]) ...
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
    "dynamicChoice", "(none)", ...
    "sources", struct([]));
end

function accepted = validateProject(project)
accepted = isstruct(project) && isscalar(project) && ...
    isfield(project, "lineWidth") && isnumeric(project.lineWidth) && ...
    isscalar(project.lineWidth) && isfinite(project.lineWidth) && ...
    isfield(project, "changeCount") && isfield(project, "actionCount") && ...
    isfield(project, "tableEditCount") && ...
    isfield(project, "dynamicChoice") && ...
    isfield(project, "sources");
end

function choices = dynamicChoices(value)
choices = "(none)";
if string(value) == "ECG"
    choices = "ECG";
end
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

function deleteIfPresent(filepath)
if isfile(filepath)
    delete(filepath);
end
end
