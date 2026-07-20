classdef GuiLayoutGaitAnalysisTest < matlab.unittest.TestCase
    % Verify Gait Analysis through the explicit App SDK runtime.
    methods (Test, TestTags = {'GUI', 'Structural', 'Workflow'})
        function nativeLayoutUsesSemanticTargets(testCase)
            setupLabKitTestPath();
            helpers = guiTestHelpers();
            helpers.assertUifigureAvailable();
            cleanup = onCleanup(@() helpers.closeAllFigures());
            figure = labkit_GaitAnalysis_app();

            assertGaitLayout(helpers, figure);
            clear cleanup
        end

        function poseDrivesAnalysisNavigationExportAndRestore(testCase)
            setupLabKitTestPath();
            helpers = guiTestHelpers();
            helpers.assertUifigureAvailable();
            outputFolder = string(tempname);
            mkdir(outputFolder);
            folderCleanup = onCleanup(@() removeTempFolder(outputFolder));
            backend = struct( ...
                "chooseOutputFolder", @(~) ...
                    labkit.app.dialog.Choice(outputFolder), ...
                "alert", @(~, ~) []);
            app = gait_analysis.definition();
            runtime = app.createMatlabRuntime([], backend);
            runtimeCleanup = onCleanup(@() runtime.close());
            figure = runtime.figureHandle();
            sampleContext = labkit.app.diagnostic.SampleContext( ...
                fullfile(outputFolder, "debug-sample"));
            pack = gait_analysis.debug.writeSamplePack(sampleContext);
            posePath = string(pack.InitialProject.inputs.sources(1) ...
                .reference.originalPath);

            runtime.applyFileSelection( ...
                "poseFile", posePath, 1);

            testCase.verifyTrue(runtime.State.session.cache.pose.ok);
            testCase.verifyEqual( ...
                runtime.State.project.parameters.frameRate, 30);
            skeleton = findall(figure, "Tag", "gaitAxes.skeleton");
            testCase.verifyNotEmpty(skeleton.Children);
            testCase.verifyEqual(skeleton.YDir, 'reverse');
            testCase.verifyEqual(string( ...
                component(figure, "poseFile.choose").Text), ...
                "Open Video Marker MAT");
            testCase.verifyEqual(string( ...
                component(figure, "poseFile.status").Value), ...
                posePath);

            runtime.applyControlValue( ...
                "originAtFirstFrameFirstPoint", true);
            testCase.verifyTrue(runtime.State.project.parameters ...
                .originAtFirstFrameFirstPoint);
            testCase.verifyFalse( ...
                runtime.State.project.results.analysis.ok);

            runtime.invokeAction("runAnalysis");

            result = runtime.State.project.results.analysis;
            testCase.verifyTrue(result.ok);
            testCase.verifyGreaterThan(height(result.frameTable), 0);
            testCase.verifyGreaterThan(height(result.stepTable), 0);
            angles = findall(figure, "Tag", "gaitAxes.angles");
            testCase.verifyNotEmpty(angles.Children);
            testCase.verifyEqual(angles.YDir, 'normal');
            row = result.stepTable(1, :);
            helpers.assertAxesContract(figure, { ...
                helpers.axesSpec(sprintf("Step 1 | frames %d-%d", ...
                    row.lift_off_frame, row.landing_frame), ...
                    "Pixel X", "Pixel Y"), ...
                helpers.axesSpec("Step 1 joint angles", ...
                    "Time (s)", "Angle (deg)"), ...
                helpers.axesSpec("Step 1 segment lengths", ...
                    "Time (s)", ...
                    "Length (" + row.coordinate_unit + ")")});
            assertDisplayGraphicsAreNonPickable(testCase, figure);
            if height(result.stepTable) > 1
                runtime.applyTableSelection("stepTable", [2 1]);
                testCase.verifyEqual( ...
                    runtime.State.session.selection.currentStepIndex, 2);
                runtime.invokeAction("previousStep");
                testCase.verifyEqual( ...
                    runtime.State.session.selection.currentStepIndex, 1);
                runtime.invokeAction("nextStep");
                testCase.verifyEqual( ...
                    runtime.State.session.selection.currentStepIndex, 2);
            end

            runtime.invokeAction("chooseOutputFolder");
            runtime.invokeAction("exportResults");
            [~, stem] = fileparts(posePath);
            expected = stem + [ ...
                "_frames.csv", "_coordinates.csv", "_steps.csv", ...
                "_summary.csv", "_gait.labkit.json"];
            for filepath = fullfile(outputFolder, expected)
                testCase.verifyTrue(isfile(filepath), ...
                    "Missing gait output: " + filepath);
            end

            projectPath = fullfile(outputFolder, "gait-project.mat");
            runtime.saveProject(runtime.State, projectPath);
            runtime.applyFileSelection( ...
                "poseFile", strings(1, 0), zeros(1, 0));
            testCase.verifyFalse(runtime.State.session.cache.pose.ok);
            runtime.restoreProject(projectPath);
            testCase.verifyTrue(runtime.State.session.cache.pose.ok);
            testCase.verifyTrue( ...
                runtime.State.project.results.analysis.ok);
            testCase.verifyEqual(string( ...
                component(figure, "poseFile.status").Value), ...
                posePath);
            clear runtimeCleanup folderCleanup
        end
    end
end

function assertGaitLayout(helpers, figure)
ids = [ ...
    "poseFile", "poseFile.choose", "poseFile.status", ...
    "sourceSummary", "runAnalysis", "analysisStatus", ...
    "iliacPoint", "hipPoint", "kneePoint", "anklePoint", "footPoint", ...
    "frameRate", "pixelsPerUnit", "unitName", ...
    "originAtFirstFrameFirstPoint", "smoothWindow", ...
    "detectionProminence", "detectionMinHeightSigma", ...
    "minLiftOffIntervalSeconds", "minSwingFrames", ...
    "maxSwingFrames", "minStepLength", "maxHipTranslation", ...
    "summaryTable", "previousStep", "nextStep", "stepTable", ...
    "chooseOutputFolder", "outputFolder", "exportResults", "appLog", ...
    "gaitAxes.skeleton", "gaitAxes.angles", "gaitAxes.segments"];
for id = ids
    assert(numel(findall(figure, "Tag", id)) == 1, ...
        "Missing Gait Analysis semantic target: %s.", id);
end
tabs = findall(figure, "Type", "uitab");
assert(isequal(sort(string({tabs.Title})), ...
    sort(["Source", "Roles + Detection", "Results + Export", "Log"])));
assert(numel(findall(figure, "Title", "Gait Preview")) >= 2);
assert(~isempty(findall(figure, "Title", "Workflow Notes")));
assert(~isempty(findall(figure, "Title", "Video Marker Project")));
assert(~isempty(findall(figure, "Title", "Keypoint Roles")));
assert(~isempty(findall(figure, "Title", "Step Detection")));
assert(isequal(string(component(figure, "stepTable").ColumnName), ...
    ["Step"; "Valid"; "Swing_s"; "Step length"]));
previous = component(figure, "previousStep");
next = component(figure, "nextStep");
assert(abs(previous.Position(2) - next.Position(2)) <= 1, ...
    "Gait step navigation must remain one horizontal action row.");
helpers.assertAxesContract(figure, { ...
    helpers.axesSpec("", "", ""), ...
    helpers.axesSpec("", "", ""), ...
    helpers.axesSpec("", "", "")});
end

function assertDisplayGraphicsAreNonPickable(testCase, figure)
axesHandles = [ ...
    component(figure, "gaitAxes.skeleton"), ...
    component(figure, "gaitAxes.angles"), ...
    component(figure, "gaitAxes.segments")];
for ax = axesHandles
    graphics = allchild(ax);
    for k = 1:numel(graphics)
        if isprop(graphics(k), "HitTest")
            testCase.verifyEqual(string(graphics(k).HitTest), "off");
        end
        if isprop(graphics(k), "PickableParts")
            testCase.verifyEqual(string(graphics(k).PickableParts), "none");
        end
    end
end
end

function value = component(figure, tag)
value = findall(figure, "Tag", char(tag));
assert(isscalar(value), "Expected one component with Tag %s.", tag);
end

function removeTempFolder(folder)
if exist(folder, "dir") == 7
    rmdir(folder, "s");
end
end
