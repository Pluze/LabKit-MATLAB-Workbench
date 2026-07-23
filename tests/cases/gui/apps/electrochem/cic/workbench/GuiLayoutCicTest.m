classdef GuiLayoutCicTest < matlab.unittest.TestCase
    %GUILAYOUTCICTEST Verify CIC GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural', 'Workflow'})
        function cic_workflow_loads_analyzes_and_plots_chrono(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            fixture = dtaFixturePath('chrono_chronopot_current_pulse_0p2ms.DTA');
            secondFixture = dtaFixturePath('chrono_chronopot_current_pulse_1ms.DTA');
            thirdFolder = string(tempname);
            mkdir(thirdFolder);
            thirdCleanup = onCleanup(@() rmdir(thirdFolder, 's'));
            thirdFixture = fullfile(thirdFolder, 'chrono_third_pulse.DTA');
            copyfile(secondFixture, thirdFixture);
            outputFolder = string(tempname);
            mkdir(outputFolder);
            outputCleanup = onCleanup(@() rmdir(outputFolder, 's'));
            backend = struct( ...
                "chooseOutputFile", @(~, ~) labkit.app.dialog.Choice( ...
                    fullfile(outputFolder, "cic_results.csv")), ...
                "alert", @(~, ~) []);
            runtime = labkit.app.internal.RuntimeFactory.createMatlab( ...
                cic.definition(), [], backend);
            runtimeCleanup = onCleanup(@() runtime.close());
            fig = runtime.figureHandle();
            assertCicLayout(h, fig);
            runtime.applyFileSelection("files", string(fixture), 1);

            testCase.verifyEqual(numel( ...
                runtime.State.project.inputs.sources), 1);
            testCase.verifyEqual(numel(runtime.State.session.cache.items), 1);
            results = findall(fig, "Tag", "results");
            data = results.Data;
            testCase.verifyEqual(size(data), [1 8], ...
                'CIC workflow should populate one batch result row.');
            testCase.verifyTrue(isnumeric(data{1, 5}) && isfinite(data{1, 5}), ...
                'CIC workflow should compute a cathodic charge value.');
            testCase.verifyTrue(ischar(data{1, 8}) || isstring(data{1, 8}), ...
                'CIC workflow should populate the safety result column.');

            testCase.verifyTrue(contains(string( ...
                findall(fig, "Tag", "detect").Value), ...
                'metadata-current'), ...
                'CIC workflow should refresh the detection summary field.');
            testCase.verifyTrue(contains(string( ...
                findall(fig, "Tag", "qt").Value), 'C'), ...
                'CIC workflow should refresh computed total charge summary fields.');
            testCase.verifyTrue(strlength(string( ...
                findall(fig, "Tag", "safe").Value)) > 1, ...
                'CIC workflow should refresh the safety summary field.');
            topAxes = findall(fig, "Tag", "plotAxes.top");
            bottomAxes = findall(fig, "Tag", "plotAxes.bottom");
            testCase.verifyNotEmpty(topAxes.Children, ...
                'CIC workflow should draw the top plot.');
            testCase.verifyNotEmpty(bottomAxes.Children, ...
                'CIC workflow should draw the bottom plot.');
            testCase.verifyFalse(isfield(runtime.State.project.inputs, 'items'), ...
                'CIC durable project must not own decoded DTA items.');
            testCase.verifyTrue(all(isfield(runtime.State.session, ...
                {'selection', 'cache'})), ...
                'CIC session should own selection and rebuildable cache state.');
            firstSourceId = string(runtime.State.project.inputs.sources(1).id);
            assertExtremaLabelsAreReadable(topAxes);
            topAxes.XLim = [-1 0];
            topAxes.YLim = [-0.01 0.01];

            paths = [string(fixture), string(secondFixture), thirdFixture];
            runtime.applyFileSelection("files", paths, 3);
            registeredSourceIds = string( ...
                {runtime.State.project.inputs.sources.id});
            testCase.verifyEqual(registeredSourceIds(1), firstSourceId, ...
                'Batch registration should preserve the first source identity.');
            testCase.verifyEqual(numel(unique(registeredSourceIds)), ...
                numel(registeredSourceIds), ...
                'Batch registration should allocate unique source identities.');
            testCase.verifyEqual(numel(runtime.State.session.cache.items), 3);
            assertCicFileSelection(testCase, runtime, 1);
            assertCicFileSelection(testCase, runtime, 2);
            assertCicFileSelection(testCase, runtime, 1);
            beforeAreaChange = results.Data;
            runtime.applyControlValue("areaOverride", "2");
            afterAreaChange = results.Data;
            for row = 1:3
                testCase.verifyEqual(afterAreaChange{row, 7}, ...
                    0.5 * beforeAreaChange{row, 7}, 'RelTol', 1e-12, ...
                    'A shared CIC area change should recompute every loaded file.');
            end
            runtime.invokeAction("exportResults");
            testCase.verifyTrue(isfile(fullfile(outputFolder, 'cic_results.csv')));
            resultManifestPath = fullfile(outputFolder, ...
                'cic_results.labkit.json');
            testCase.verifyTrue(isfile(resultManifestPath), ...
                'CIC export should write a standard result manifest.');
            resultManifest = jsondecode(fileread(resultManifestPath));
            testCase.verifyEqual(string(resultManifest.format), "labkit.result");
            testCase.verifyEqual(string(resultManifest.outputs.status), "success");

            projectPath = fullfile(outputFolder, 'cic-project.mat');
            runtime.saveProject(runtime.State, projectPath);
            saved = load(projectPath, 'labkitProject');
            testCase.verifyEqual(saved.labkitProject.app.payloadVersion, 1);
            testCase.verifyFalse(isfield( ...
                saved.labkitProject.payload.inputs, 'items'), ...
                'CIC project files must exclude decoded DTA items.');
            runtime.applyFileSelection("files", strings(1, 0), zeros(1, 0));
            runtime.restoreProject(projectPath);
            testCase.verifyEqual(numel(runtime.State.session.cache.items), 3, ...
                'CIC project reopen should rebuild decoded sources.');
            testCase.verifyEqual( ...
                string({runtime.State.project.inputs.sources.id}), ...
                registeredSourceIds, ...
                'CIC project reopen should preserve registered source identities.');
            testCase.verifyEqual(topAxes.XLim, [-1 0], ...
                'CIC redraw should preserve the user viewport.');
            testCase.verifyEqual(topAxes.YLim, [-0.01 0.01], ...
                'CIC redraw should preserve the user viewport.');

            runtime.applyFileSelection("files", paths(1:2), zeros(1, 0));
            testCase.verifyEqual( ...
                string({runtime.State.project.inputs.sources.id}), ...
                registeredSourceIds(1:2), ...
                'Removing a source should preserve retained source identities.');
            runtime.applyFileSelection("files", paths, 3);
            finalSourceIds = string({runtime.State.project.inputs.sources.id});
            testCase.verifyEqual(finalSourceIds(1:2), ...
                registeredSourceIds(1:2), ...
                'Re-adding a source should not renumber retained sources.');
            testCase.verifyEqual(numel(unique(finalSourceIds)), ...
                numel(finalSourceIds), ...
                'Re-adding a source should allocate a collision-free identity.');

            runtime.applyFileSelection("files", strings(1, 0), zeros(1, 0));
            testCase.verifyEmpty(runtime.State.project.inputs.sources);
            testCase.verifyEmpty(topAxes.Children, ...
                'CIC clear-all should remove stale plot markers and annotations.');
            testCase.verifyEmpty(bottomAxes.Children, ...
                'CIC clear-all should remove stale bottom plot markers and annotations.');
            clear runtimeCleanup outputCleanup thirdCleanup;
        end
    end
end

function assertCicFileSelection(testCase, runtime, index)
    runtime.applyFilePanelSelection("files", index);
    testCase.verifyEqual(runtime.State.session.selection.files.Indices, index, ...
        'Selecting an imported CIC file should update canonical selection.');
end

function assertCicLayout(h, fig)
    h.assertStartupSucceeded(fig);
    ids = ["files", "preset", "cathLimit", "anodLimit", "delayUs", ...
        "areaOverride", "pulseMode", "cicMode", "cicUnit", ...
        "useMeasuredCurrent", "results", "exportResults", ...
        "plotAxes.top", "plotAxes.bottom"];
    for id = ids
        assert(numel(findall(fig, "Tag", id)) == 1, ...
            "Missing CIC semantic target: %s.", id);
    end
end

function assertExtremaLabelsAreReadable(ax)
    texts = findall(ax, 'Type', 'text');
    labels = string(get(texts, 'String'));
    if isscalar(texts)
        labels = string(texts.String);
    end
    emc = texts(contains(labels, "Emc ="));
    ema = texts(contains(labels, "Ema ="));
    assert(~isempty(emc) && ~isempty(ema), ...
        'CIC VT plot should label Emc and Ema markers.');
    assert(isWhiteBackground(emc(1)) && isWhiteBackground(ema(1)), ...
        'CIC Emc/Ema labels should have a readable background.');
    assert(~strcmp(emc(1).HorizontalAlignment, ema(1).HorizontalAlignment), ...
        'CIC Emc/Ema labels should be staggered to reduce overlap.');
end

function tf = isWhiteBackground(textHandle)
    color = textHandle.BackgroundColor;
    if ischar(color) || isstring(color)
        tf = strcmp(char(color), 'w');
    else
        tf = isnumeric(color) && isequal(size(color), [1 3]) && ...
            all(abs(color - [1 1 1]) < 1e-12);
    end
end
