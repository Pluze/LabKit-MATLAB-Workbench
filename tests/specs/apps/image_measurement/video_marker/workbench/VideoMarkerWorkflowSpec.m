classdef VideoMarkerWorkflowSpec < matlab.unittest.TestCase
    %VIDEOMARKERWORKFLOWSPEC Specify marking, exports, and App-owned snapshots.

    methods (Test, TestTags = {'Contract:workflow', 'Env:hidden-gui'})
        function reviewsPredictionsWithoutMutatingAnnotations(testCase)
            folder = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            fixture = testfixtures.video_marker.project(string(folder));
            definition = video_marker.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createMatlabRuntime(definition, [], struct("alert", @(~,~) []), journal);
            cleanup = onCleanup(@() runtime.close());
            runtime.applyControlValue("skeletonPreset", "Three-point chain");
            runtime.invokeAction("useSkeletonPreset");
            runtime.applyFileSelection("videoFile", fixture.inputs.sources(1).path, 1);
            runtime.applyInteraction("framePoints", "interactionChanged", [24 34;32 38;40 42]);
            runtime.applyControlValue("predictionEndFrame", 3);
            runtime.invokeAction("predictToFrame");
            original = runtime.State.project.annotations.frames;
            testCase.verifyEqual(original.frameSource(2:3), ...
                repmat(video_marker.frameAnnotations.sourceCode("predicted"), 2, 1));
            runtime.applyControlValue("reviewMode", "Predicted");
            runtime.invokeAction("reviewPrevious");
            testCase.verifyEqual(runtime.State.session.cache.frameIndex, 2);
            runtime.invokeAction("reviewNext");
            testCase.verifyEqual(runtime.State.session.cache.frameIndex, 3);
            runtime.applyControlValue("reviewMode", "Unmarked");
            runtime.invokeAction("reviewNext");
            testCase.verifyEqual(runtime.State.session.cache.frameIndex, 4);
            runtime.applyControlValue("reviewMode", "Low/unknown confidence");
            runtime.applyControlValue("reviewThreshold", 1);
            runtime.invokeAction("reviewPrevious");
            testCase.verifyLessThan(runtime.State.session.cache.frameIndex, 4);
            runtime.applyControlValue("reviewMode", "Unreviewed");
            testCase.verifyEqual(runtime.State.project.annotations.frames, original);
            tab = findall(runtime.figureHandle(), "Type", "uitab", "Title", "Video");
            tab.Parent.SelectedTab = tab;
            exportapp(runtime.figureHandle(), labkittest.visualEvidencePath("video-review", ".png"));
            clear cleanup
        end

        function designsAnEditableSkeletonBeforeOpeningVideo(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            definition = video_marker.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createMatlabRuntime( ...
                definition, [], struct("alert", @(~, ~) []), journal);
            cleanup = onCleanup(@() runtime.close());

            runtime.applyControlValue("skeletonPreset", "Three-point chain");
            runtime.invokeAction("useSkeletonPreset");
            testCase.verifyEqual( ...
                string(runtime.State.project.annotations.skeleton.pointNames), ...
                ["point1"; "point2"; "point3"]);

            keypointTable = findall(runtime.figureHandle(), "Tag", "keypointTable");
            data = keypointTable.Data;
            data{1, 2} = "origin";
            runtime.applyTableEdit("keypointTable", ...
                labkit.app.event.TableCellEdit(RowIndex=1, ColumnIndex=2, ...
                    PreviousValue="point1", NewValue="origin", Data=data));
            runtime.applyTableSelection("keypointTable", [2 2]);
            runtime.invokeAction("moveKeypointDown");
            runtime.invokeAction("moveKeypointUp");
            runtime.invokeAction("addKeypoint");
            testCase.verifyNumElements( ...
                runtime.State.project.annotations.skeleton.pointNames, 4);
            runtime.invokeAction("removeKeypoint");
            testCase.verifyEqual( ...
                string(runtime.State.project.annotations.skeleton.pointNames), ...
                ["origin"; "point2"; "point3"]);

            runtime.applyControlValue("connectionFrom", "origin");
            runtime.applyControlValue("connectionTo", "point3");
            edgeCount = size(runtime.State.project.annotations.skeleton.edges, 1);
            runtime.invokeAction("addConnection");
            testCase.verifyEqual( ...
                size(runtime.State.project.annotations.skeleton.edges, 1), ...
                edgeCount + 1);
            runtime.invokeAction("connectInOrder");
            runtime.applyTableSelection("connectionTable", [1 1]);
            runtime.invokeAction("removeConnection");
            testCase.verifyEqual( ...
                size(runtime.State.project.annotations.skeleton.edges, 1), 2);
            clear cleanup
        end

        function marksPredictsExportsAndRestoresSyntheticVideo(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            project = testfixtures.video_marker.project(string(folder));
            markerPath = fullfile(folder, "markers.csv");
            coordinatePath = fullfile(folder, "coordinates.csv");
            annotatedVideoPath = fullfile(folder, "annotated.mp4");
            saved = fullfile(folder, "video-marker-project.mat");
            backend = struct( ...
                "chooseOutputFile", @(~, defaultPath) chooseOutput( ...
                    defaultPath, markerPath, coordinatePath, ...
                    annotatedVideoPath, saved), ...
                "chooseInputFile", @(filter, ~) chooseInput( ...
                    filter, markerPath, saved), ...
                "choose", @(~, ~, ~, ~, ~) ...
                    labkit.app.dialog.Choice("Discard and start new"), ...
                "inform", @(~, ~) [], ...
                "alert", @(~, ~) []);
            definition = video_marker.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createMatlabRuntime( ...
                definition, project, backend, ...
                journal);
            cleanup = onCleanup(@() runtime.close());

            videoPath = runtime.State.project.inputs.sources(1).path;
            runtime.applyFileSelection("videoFile", videoPath, 1);
            points = [24 34; 32 38; 40 42; 48 46; 56 50];
            runtime.applyInteraction("framePoints", "interactionChanged", points);
            runtime.invokeAction("predictToFrame");
            runtime.applyControlValue("currentFrame", 1);
            testCase.verifyEqual( ...
                runtime.State.session.selection.currentFrame, 1);
            runtime.invokeAction("nextFrame");
            runtime.invokeAction("previousFrame");
            runtime.invokeAction("undoPoint");
            testCase.verifySize(video_marker.frameAnnotations.framePoints( ...
                runtime.State.project.annotations.frames, 1), [4 2]);
            runtime.invokeAction("clearFramePoints");
            testCase.verifyEmpty(video_marker.frameAnnotations.framePoints( ...
                runtime.State.project.annotations.frames, 1));
            runtime.applyInteraction("framePoints", "interactionChanged", points);
            runtime.invokeAction("predictToFrame");
            runtime.applyControlValue("scaleReferencePixels", 24);
            runtime.invokeAction("measureScaleReference");
            runtime.applyInteraction("scaleReference", "interactionChanged", [10 10; 30 10]);
            runtime.applyControlValue("scaleReferenceLength", 2);
            runtime.applyControlValue("scaleCalibrationUnit", "mm");
            runtime.applyControlValue("scaleBarLength", 1);
            runtime.applyControlValue("scaleBarPosition", "Top left");
            runtime.applyControlValue("scaleBarColor", "White");
            runtime.invokeAction("placeScaleBar");
            testCase.verifyNotEmpty(runtime.State.session.view.scaleBar);
            runtime.applyControlValue("coordinateUnitMode", "calibrated_physical");
            runtime.applyControlValue("coordinateOriginMode", "first_point");
            runtime.applyControlValue("coordinateYAxisMode", "down");
            runtime.applyControlValue("coordinateStartFrame", 1);
            runtime.applyControlValue("coordinateEndFrame", 1);
            runtime.invokeAction("exportMarkerCsv");
            runtime.invokeAction("exportCoordinateCsv");
            if ismac || ispc
                runtime.invokeAction("exportAnnotatedVideo");
            end

            testCase.verifyEqual(video_marker.frameAnnotations.sourceName( ...
                runtime.State.project.annotations.frames.frameSource(2)), "predicted");
            testCase.verifyTrue(runtime.State.project.annotations.calibration.isCalibrated);
            testCase.verifyTrue(isfile(markerPath));
            testCase.verifyTrue(isfile(coordinatePath));
            testCase.verifyEqual(isfile(annotatedVideoPath), ismac || ispc);
            testCase.verifyTrue(isfile(runtime.State.project.results.markerOutputPath));
            testCase.verifyTrue(isfile(runtime.State.project.results.coordinateOutputPath));
            runtime.invokeAction("clearFramePoints");
            runtime.invokeAction("importMarkerCsv");
            testCase.verifyEqual(video_marker.frameAnnotations.framePoints( ...
                runtime.State.project.annotations.frames, 1), points);
            runtime.invokeAction("saveProject");
            testCase.verifyTrue(isfile(saved));
            runtime.invokeAction("openProject");
            testCase.verifyEqual(video_marker.frameAnnotations.framePoints( ...
                runtime.State.project.annotations.frames, 1), points);
            runtime.invokeAction("newSetup");
            testCase.verifyEmpty(runtime.State.project.inputs.sources);
            testCase.verifyEmpty( ...
                runtime.State.project.annotations.skeleton.pointNames);
            clear cleanup
        end

        function rendersAfterRestoringAppOwnedSnapshot(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            project = testfixtures.video_marker.project(string(folder));
            project.inputs.sources(1).id = "video-1";
            markerPath = fullfile(folder, "restored-markers.csv");
            coordinatePath = fullfile(folder, "restored-coordinates.csv");
            annotatedVideoPath = fullfile(folder, "restored-annotated.mp4");
            namedProjectPath = fullfile(folder, "named-project.mat");
            videoPath = project.inputs.sources(1).path;
            expectedOutputFolder = fullfile(fileparts(videoPath), ...
                "video_marker");
            backend = struct( ...
                "chooseOutputFile", @(~, defaultPath) ...
                    chooseRestoredOutput(defaultPath, ...
                    expectedOutputFolder, markerPath, coordinatePath, ...
                    annotatedVideoPath, namedProjectPath), ...
                "chooseInputFile", @(~, ~) ...
                    labkit.app.dialog.Choice(namedProjectPath), ...
                "inform", @(~, ~) [], ...
                "alert", @(~, ~) []);
            definition = video_marker.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createMatlabRuntime( ...
                definition, project, backend, journal);
            cleanup = onCleanup(@() runtime.close());
            points = [24 34; 32 38; 40 42; 48 46; 56 50];

            runtime.applyInteraction( ...
                "framePoints", "interactionChanged", points);
            runtime.invokeAction("predictToFrame");
            runtime.invokeAction("exportMarkerCsv");
            runtime.applyControlValue("coordinateEndFrame", 1);
            runtime.invokeAction("exportCoordinateCsv");
            if ismac || ispc
                runtime.invokeAction("exportAnnotatedVideo");
            end
            runtime.invokeAction("saveProject");
            runtime.invokeAction("openProject");

            testCase.verifyTrue(isfile(markerPath));
            testCase.verifyTrue(isfile(coordinatePath));
            testCase.verifyEqual(isfile(annotatedVideoPath), ismac || ispc);
            testCase.verifyTrue(isfile(namedProjectPath));
            if ismac || ispc
                rendered = VideoReader(annotatedVideoPath);
                testCase.verifyEqual(rendered.NumFrames, 6);
            end
            testCase.verifyEqual( ...
                video_marker.frameAnnotations.sourceName( ...
                runtime.State.project.annotations.frames.frameSource(2)), ...
                "predicted");
            testCase.verifyEqual( ...
                video_marker.frameAnnotations.framePoints( ...
                runtime.State.project.annotations.frames, 1), points);
            clear cleanup
        end
    end
end

function choice = chooseInput(filter, markerPath, projectPath)
if contains(strjoin(string(filter)), "csv", IgnoreCase=true)
    choice = labkit.app.dialog.Choice(markerPath);
else
    choice = labkit.app.dialog.Choice(projectPath);
end
end

function choice = chooseRestoredOutput(defaultPath, expectedFolder, ...
        markerPath, coordinatePath, annotatedVideoPath, projectPath)
defaultPath = string(defaultPath);
if endsWith(defaultPath, ".mat")
    choice = labkit.app.dialog.Choice(projectPath);
    return
end
assert(startsWith(defaultPath, string(expectedFolder) + filesep), ...
    "Restored Video Marker outputs must default beside the source video.");
if contains(defaultPath, "markers", IgnoreCase=true)
    choice = labkit.app.dialog.Choice(markerPath);
elseif contains(defaultPath, "coordinates", IgnoreCase=true)
    choice = labkit.app.dialog.Choice(coordinatePath);
else
    assert(endsWith(defaultPath, ".mp4"), ...
        "Annotated-video output must use the MP4 container.");
    choice = labkit.app.dialog.Choice(annotatedVideoPath);
end
end

function choice = chooseOutput(defaultPath, markerPath, coordinatePath, ...
        annotatedVideoPath, projectPath)
if endsWith(string(defaultPath), ".mat")
    choice = labkit.app.dialog.Choice(projectPath);
    return
end
if contains(string(defaultPath), "markers", IgnoreCase=true)
    choice = labkit.app.dialog.Choice(markerPath);
elseif contains(string(defaultPath), "annotated", IgnoreCase=true)
    choice = labkit.app.dialog.Choice(annotatedVideoPath);
else
    choice = labkit.app.dialog.Choice(coordinatePath);
end
end
