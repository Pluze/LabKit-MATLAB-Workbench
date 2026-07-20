classdef GuiLayoutCscTest < matlab.unittest.TestCase
    %GUILAYOUTCSCTEST Verify CSC GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural', 'Workflow'})
        function csc_workflow_loads_cvct_compares_and_plots(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            fixture = string(dtaFixturePath( ...
                'cv_cyclic_voltammetry_pt_reference.DTA'));
            secondFixture = string(dtaFixturePath( ...
                'cv_cyclic_voltammetry_pt_replicate.DTA'));
            outputFolder = string(tempname);
            mkdir(outputFolder);
            outputCleanup = onCleanup(@() rmdir(outputFolder, 's'));
            backend = struct( ...
                "chooseOutputFile", @(~, ~) labkit.app.dialog.Choice( ...
                    fullfile(outputFolder, "csc_all_cycles.csv")), ...
                "alert", @(~, ~) []);
            runtime = labkit.app.internal.RuntimeFactory.createMatlab( ...
                csc.definition(), [], backend);
            runtimeCleanup = onCleanup(@() runtime.close());
            fig = runtime.figureHandle();
            assertCscLayout(h, fig);

            choices = csc.analysisRun.analysisChoices();
            runtime.applyControlValue("mode", choices.modes(2));
            runtime.applyControlValue("mode", choices.modes(1));
            runtime.applyFileSelection("files", fixture, 1);

            testCase.verifyEqual(numel( ...
                runtime.State.project.inputs.sources), 1);
            testCase.verifyFalse(isfield( ...
                runtime.State.project.inputs, 'items'), ...
                'CSC durable project must not own decoded DTA items.');
            testCase.verifyEqual(numel(runtime.State.session.cache.items), 1);
            firstSourceId = string( ...
                runtime.State.project.inputs.sources(1).id);

            curve = findall(fig, "Tag", "curve");
            testCase.verifyTrue(contains(string( ...
                findall(fig, "Tag", "scanRate").Value), 'V/s'));
            testCase.verifyGreaterThan(numel(curve.Items), 1);
            testCase.verifyEqual(string(curve.Value), choices.allCycles);
            cycleResults = findall(fig, "Tag", "cycleResults");
            testCase.verifyEqual(size(cycleResults.Data, 1), ...
                numel(curve.Items) - 1, ...
                'CSC workflow should show one result row per parsed cycle.');

            runtime.applyControlValue("ignoreEdgeCycles", true);
            testCase.verifyEqual(size(cycleResults.Data, 1), ...
                max(0, numel(curve.Items) - 3));
            runtime.applyControlValue("ignoreEdgeCycles", false);
            topAxes = findall(fig, "Tag", "plotAxes.top");
            bottomAxes = findall(fig, "Tag", "plotAxes.bottom");
            testCase.verifyGreaterThan(numel(topAxes.Children), 1, ...
                'CSC all-cycle workflow should draw multiple cycle lines.');

            staleXLim = [100 101];
            topAxes.XLim = staleXLim;
            topX = findall(fig, "Tag", "topX");
            nextTopX = nextChoice(topX);
            runtime.applyControlValue("topX", nextTopX);
            testCase.verifyEqual(topAxes.XLim, staleXLim, ...
                'Managed plot refresh should preserve the user viewport.');

            runtime.applyControlValue("curve", string(curve.Items{2}));
            staleYLim = [1 2];
            topAxes.YLim = staleYLim;
            topY = findall(fig, "Tag", "topY");
            runtime.applyControlValue("topY", nextChoice(topY));
            testCase.verifyEqual(topAxes.YLim, staleYLim, ...
                'Managed single-cycle refresh should preserve the viewport.');
            testCase.verifyTrue(contains(string( ...
                findall(fig, "Tag", "qct").Value), 'C'));
            testCase.verifyTrue(contains(string( ...
                findall(fig, "Tag", "qcv").Value), 'C'));
            testCase.verifyTrue(strlength(string( ...
                findall(fig, "Tag", "status").Value)) > 1);
            testCase.verifyNotEmpty(bottomAxes.Children);

            paths = [fixture, secondFixture];
            runtime.applyFileSelection("files", paths, 2);
            registeredSourceIds = string( ...
                {runtime.State.project.inputs.sources.id});
            testCase.verifyEqual(registeredSourceIds(1), firstSourceId);
            testCase.verifyEqual(numel(unique(registeredSourceIds)), 2);
            runtime.applyFilePanelSelection("files", 1);
            testCase.verifyEqual( ...
                runtime.State.session.selection.files.Indices, 1);

            runtime.invokeAction("exportResults");
            exportPath = fullfile(outputFolder, "csc_all_cycles.csv");
            testCase.verifyTrue(isfile(exportPath));
            manifestPath = fullfile( ...
                outputFolder, "csc_all_cycles.labkit.json");
            testCase.verifyTrue(isfile(manifestPath));
            manifest = jsondecode(fileread(manifestPath));
            testCase.verifyEqual(string(manifest.format), "labkit.result");

            projectPath = fullfile(outputFolder, "csc-project.mat");
            runtime.saveProject(runtime.State, projectPath);
            saved = load(projectPath, 'labkitProject');
            testCase.verifyEqual(saved.labkitProject.app.payloadVersion, 1);
            testCase.verifyFalse(isfield( ...
                saved.labkitProject.payload.inputs, 'items'));
            runtime.applyFileSelection( ...
                "files", strings(1, 0), zeros(1, 0));
            runtime.restoreProject(projectPath);
            testCase.verifyEqual(numel(runtime.State.session.cache.items), 2);
            testCase.verifyEqual(string( ...
                {runtime.State.project.inputs.sources.id}), ...
                registeredSourceIds);

            runtime.applyFileSelection("files", fixture, 1);
            testCase.verifyEqual(string( ...
                runtime.State.project.inputs.sources.id), firstSourceId);
            runtime.applyFileSelection("files", paths, 2);
            finalSourceIds = string( ...
                {runtime.State.project.inputs.sources.id});
            testCase.verifyEqual(finalSourceIds(1), firstSourceId);
            testCase.verifyEqual(numel(unique(finalSourceIds)), 2);

            runtime.applyFileSelection( ...
                "files", strings(1, 0), zeros(1, 0));
            testCase.verifyEmpty(runtime.State.project.inputs.sources);
            testCase.verifyEmpty(topAxes.Children);
            testCase.verifyEmpty(bottomAxes.Children);
            clear runtimeCleanup outputCleanup cleanup;
        end
    end
end

function value = nextChoice(component)
items = string(component.Items);
value = items(find(items ~= string(component.Value), 1, 'first'));
assert(~isempty(value), 'CSC fixture should expose another axis choice.');
end

function assertCscLayout(h, fig)
h.assertStartupSucceeded(fig);
ids = ["files", "reloadSelected", "curve", "topX", "topY", ...
    "bottomX", "bottomY", "mode", "area", "ignoreEdgeCycles", ...
    "cycleResults", "exportResults", "exportVoltageCurrent", ...
    "plotAxes.top", "plotAxes.bottom"];
for id = ids
    assert(numel(findall(fig, "Tag", id)) == 1, ...
        "Missing CSC semantic target: %s.", id);
end
end
