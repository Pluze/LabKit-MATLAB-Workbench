classdef UiAuthoringErgonomicsTest < matlab.unittest.TestCase
    % Verify the replacement SDK's standard authoring path stays low-boilerplate.
    methods (Test)
        function staticAppNeedsOnlyApplicationAndLayout(testCase)
            setupLabKitTestPath();
            app = minimalApplication(labkit.ui.Layout.workbench({}));

            testCase.verifyEmpty(app.TargetIds);
            testCase.verifyEmpty(app.commandIdsForRuntime());
        end

        function boundFieldNeedsNoCommandOrPresenter(testCase)
            setupLabKitTestPath();
            layout = labkit.ui.Layout.workbench({ ...
                labkit.ui.Layout.field("gain", Kind="numeric", ...
                    Bind="project.parameters.gain")});
            app = minimalApplication(layout, ...
                Project=labkit.ui.ProjectContract( ...
                    Version=1, Create=@createProject, ...
                    Validate=@validateProject));
            runtime = app.createRuntimeForTesting();

            runtime.applyBinding("gain", 3);

            testCase.verifyEqual(runtime.State.project.parameters.gain, 3);
            testCase.verifyEmpty(app.commandIdsForRuntime());
        end

        function layoutSignalsAndCapabilitiesNeedNoDuplicateLists(testCase)
            setupLabKitTestPath();
            run = labkit.ui.Command("run", @runApp);
            layout = labkit.ui.Layout.workbench({ ...
                labkit.ui.Layout.action("run", "Run", run)});
            app = minimalApplication(layout);

            testCase.verifyEqual(app.commandIdsForRuntime(), "run");
            testCase.verifyEqual(app.Capabilities, [ ...
                "dispatch", "workflow", "diagnostics", "dialogs", ...
                "project", "render", "resources", "results"]);
        end

        function simpleProjectContractNeedsNoLocalCallbacks(testCase)
            setupLabKitTestPath();
            contract = labkit.ui.ProjectContract();

            testCase.verifyEqual(contract.Create(), struct());
            testCase.verifyTrue(contract.Validate(struct("value", 1)));
        end

        function standardFilePanelNeedsNoCommands(testCase)
            setupLabKitTestPath();
            project = labkit.ui.ProjectContract( ...
                Version=1, Create=@createFileProject, ...
                Validate=@validateFileProject);
            layout = labkit.ui.Layout.workbench({ ...
                labkit.ui.Layout.filePanel("files", ...
                    Bind="project.inputs.sources", ...
                    SelectionBind="session.selection.files")});
            app = minimalApplication(layout, Project=project, ...
                Session=@createFileSession);
            runtime = app.createRuntimeForTesting();

            runtime.applyFileSelection( ...
                "files", ["first.csv"; "second.csv"], 2);

            testCase.verifyEmpty(app.commandIdsForRuntime());
            testCase.verifyEqual(runtime.sourcePaths( ...
                runtime.State.project.inputs.sources, strings(0, 1)), ...
                ["first.csv"; "second.csv"]);
            testCase.verifyEqual( ...
                runtime.State.session.selection.files.Indices, 2);
        end
    end
end

function app = minimalApplication(layout, varargin)
    app = labkit.ui.Application( ...
        "Command", "labkit_AuthoringProbe_app", ...
        "Id", "probe.authoring", "Title", "Authoring probe", ...
        "Family", "Tests", "AppVersion", "1.0.0", ...
        "Updated", "2026-07-19", "Requirements", [], ...
        "Layout", layout, varargin{:});
end

function project = createProject()
    project = struct("parameters", struct("gain", 1));
end

function accepted = validateProject(project)
    accepted = isstruct(project) && isscalar(project) && ...
        isfield(project, "parameters") && ...
        isstruct(project.parameters) && isscalar(project.parameters) && ...
        isfield(project.parameters, "gain") && ...
        isnumeric(project.parameters.gain) && ...
        isscalar(project.parameters.gain) && isfinite(project.parameters.gain);
end

function state = runApp(state, ~)
end

function project = createFileProject()
project = struct("inputs", struct("sources", struct([])));
end

function accepted = validateFileProject(project)
accepted = isstruct(project) && isscalar(project) && ...
    isfield(project, "inputs") && isstruct(project.inputs) && ...
    isfield(project.inputs, "sources") && isstruct(project.inputs.sources);
end

function session = createFileSession(~)
session = struct("selection", struct( ...
    "files", labkit.ui.Selection()));
end
