classdef LayoutControlStateSpec < matlab.unittest.TestCase
    % LAYOUTCONTROLSTATESPEC Regression: canvas and panel controls must present the complete multi-panel editor state.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function provesLayoutControlState(testCase)
            editor = figure_studio.figureDocument.editorState( ...
                {snapshot("A"), snapshot("B")});
            editor.selectedPanelIds = string({editor.document.panels.id});

            view = figure_studio.layoutEditing.present(editor, true);
            definition = fragmentDefinition( ...
                figure_studio.layoutEditing.layoutSection());

            testCase.verifyTrue(definition.validateViewSnapshot(view));
        end
    end
end

function definition = fragmentDefinition(section)
definition = labkit.app.Definition(Entrypoint="labkit_FragmentProbe_app", ...
    AppId="fragment_probe", Title="Fragment probe", Family="Tests", ...
    AppVersion="1.0.0", Updated="2026-08-24", ...
    Workbench=labkit.app.layout.workbench({section}));
end

function data = snapshot(name)
data = struct("axes", struct("title", name, "xLim", [0 1], ...
    "yLim", [0 1], "zLim", [0 1], "xTick", [0 1], ...
    "yTick", [0 1], "zTick", [], "xTickLabel", ["0" "1"], ...
    "yTickLabel", ["0" "1"], "zTickLabel", strings(0, 1)), ...
    "objects", struct([]), "warnings", strings(0, 1));
end
