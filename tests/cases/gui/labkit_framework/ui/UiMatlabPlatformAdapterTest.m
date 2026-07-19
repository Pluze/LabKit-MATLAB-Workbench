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
                "labkit:ui:runtime:ActionFailed");

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
            runtime.applyFileSelection("files", ["one.DTA", "two.DTA"], [1 2]);
            files = component(figure, "files");
            files.Value = files.Items(2);
            files.ValueChangedFcn(files, struct());

            testCase.verifyEqual(runtime.State.project.lineWidth, 2);
            testCase.verifyEqual(runtime.State.project.changeCount, 1);
            testCase.verifyEqual(runtime.State.project.actionCount, 1);
            testCase.verifyEqual(runtime.State.session.sourceCount, 2);
            testCase.verifyEqual(runtime.State.session.selection.Indices, 2);
            clear cleanup
        end
    end
end

function app = chronoLikeApplication()
run = labkit.ui.Command("run", @runAnalysis);
changed = labkit.ui.Command("lineWidthChanged", @lineWidthChanged, Role="value");
content = labkit.ui.Layout.group("controls", { ...
    labkit.ui.Layout.action("run", "Run", run), ...
    labkit.ui.Layout.field("timeUnit", Kind="choice", ...
        Value="Time (s)", Choices=["Time (s)", "Time (ms)"]), ...
    labkit.ui.Layout.panner("lineWidth", Value=1, Limits=[0.5 5], ...
        Bind="project.lineWidth", Changed=changed), ...
    labkit.ui.Layout.filePanel("files", Bind="project.sources", ...
        SelectionBind="session.selection")});
workspace = labkit.ui.Layout.workspace();
workspace = workspace.page("analysis", "Analysis", ...
    labkit.ui.Layout.previewArea("preview", Renderers="draw"));
app = labkit.ui.Application(Command="labkit_ChronoProbe_app", ...
    Id="probe.chrono", Title="Chrono probe", Family="Tests", ...
    AppVersion="1.0.0", Updated="2026-07-19", Requirements=[], ...
    Project=labkit.ui.ProjectContract(Version=1, ...
        Create=@createProject, Validate=@validateProject), ...
    Session=@createSession, ...
    Present=@presentProbe, ...
    Layout=labkit.ui.Layout.workbench({content, ...
        labkit.ui.Layout.logPanel("log"), ...
        labkit.ui.Layout.statusPanel("status")}, Workspace=workspace), ...
    Renderers=struct("draw", @draw));
end

function view = presentProbe(state)
view = labkit.ui.Presentation() ...
    .enabled("run", false) ...
    .value("timeUnit", "Time (s)") ...
    .choices("timeUnit", ["Time (s)", "Time (ms)"]) ...
    .value("lineWidth", state.project.lineWidth) ...
    .limits("lineWidth", [0.5 5]) ...
    .files("files", ["first.DTA", "second.DTA"]) ...
    .text("log", "Loaded two files") ...
    .text("status", "Ready") ...
    .workspacePage("analysis", Enabled=true, Status="Ready") ...
    .plot("preview", "draw", state.project.lineWidth);
end

function project = createProject()
project = struct("lineWidth", 1, "changeCount", 0, "actionCount", 0, ...
    "sources", struct([]));
end

function accepted = validateProject(project)
accepted = isstruct(project) && isscalar(project) && ...
    isfield(project, "lineWidth") && isnumeric(project.lineWidth) && ...
    isscalar(project.lineWidth) && isfinite(project.lineWidth) && ...
    isfield(project, "changeCount") && isfield(project, "actionCount") && ...
    isfield(project, "sources");
end

function draw(axes, scale)
cla(axes(1));
plot(axes(1), 1:3, scale * (1:3));
xlim(axes(1), [0 10]);
ylim(axes(1), [0 20]);
if scale == 4
    error("probe:RendererFailure", "Injected renderer failure.");
end
end

function state = runAnalysis(state, ~)
state.project.actionCount = state.project.actionCount + 1;
end

function state = lineWidthChanged(state, ~, ~)
state.project.changeCount = state.project.changeCount + 1;
end

function session = createSession(project, ~)
session = struct("selection", labkit.ui.Selection(), ...
    "sourceCount", numel(project.sources));
end

function value = component(figure, tag)
value = findall(figure, "Tag", char(tag));
assert(isscalar(value), "Expected one component with Tag %s.", tag);
end
