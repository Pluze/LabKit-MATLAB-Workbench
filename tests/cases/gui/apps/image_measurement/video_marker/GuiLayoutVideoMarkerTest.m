classdef GuiLayoutVideoMarkerTest < matlab.unittest.TestCase
    % Verify Video Marker through the explicit App SDK runtime.
    methods (Test, TestTags = {'GUI', 'Structural', 'Workflow'})
        function nativeLayoutUsesSemanticTargets(testCase)
            setupLabKitTestPath();
            helpers = guiTestHelpers();
            helpers.assertUifigureAvailable();
            runtime = video_marker.definition().createMatlabRuntime();
            cleanup = onCleanup(@() runtime.close());
            figure = runtime.figureHandle();

            ids = ["skeletonPreset", "useSkeletonPreset", ...
                "keypointTable", "connectionTable", "videoFile", ...
                "currentFrame", "previousFrame", "nextFrame", ...
                "undoPoint", "clearFramePoints", ...
                "measureScaleReference", "placeScaleBar", ...
                "importMarkerCsv", "exportMarkerCsv", ...
                "exportCoordinateCsv", "videoPreview.video"];
            for id = ids
                testCase.verifyEqual(numel(findall( ...
                    figure, "Tag", id)), 1);
            end
            testCase.verifyEmpty(getappdata(figure, "labkitUiRegistry"));
            clear cleanup
        end

        function videoDrivesMarkingPredictionScaleAndExport(testCase)
            setupLabKitTestPath();
            helpers = guiTestHelpers();
            helpers.assertUifigureAvailable();
            folder = string(tempname);
            mkdir(folder);
            folderCleanup = onCleanup(@() removeTempFolder(folder));
            videoPath = fullfile(folder, "synthetic.avi");
            coordinatePath = fullfile(folder, "coordinates.csv");
            writeSyntheticVideo(videoPath);
            backend = struct( ...
                "chooseOutputFile", @(~, ~) ...
                    labkit.app.dialog.Choice(coordinatePath), ...
                "alert", @(~, ~) []);
            runtime = video_marker.definition().createMatlabRuntime([], backend);
            runtimeCleanup = onCleanup(@() runtime.close());

            runtime.invokeAction("useSkeletonPreset");
            testCase.verifyEqual( ...
                runtime.State.project.annotations.skeleton.pointNames, ...
                ["iliac"; "hip"; "knee"; "ankle"; "foot"]);
            runtime.applyFileSelection("videoFile", videoPath, 1);
            testCase.verifyEqual(runtime.State.session.cache.videoInfo.frameCount, 6);
            testCase.verifySize(runtime.State.project.annotations.frames.coords, ...
                [6 5 2]);

            points = [24 34; 32 38; 40 42; 48 46; 56 50];
            runtime.applyInteraction( ...
                "framePoints", "interactionChanged", points);
            testCase.verifyEqual(video_marker.frameAnnotations.statusName( ...
                runtime.State.project.annotations.frames.frameStatus(1)), ...
                "confirmed");
            runtime.invokeAction("nextFrame");
            testCase.verifyEqual(runtime.State.session.selection.currentFrame, 2);
            predicted = video_marker.frameAnnotations.framePoints( ...
                runtime.State.project.annotations.frames, 2);
            testCase.verifySize(predicted, [5 2]);
            testCase.verifyTrue(all(isfinite(predicted), "all"));
            testCase.verifyEqual(video_marker.frameAnnotations.sourceName( ...
                runtime.State.project.annotations.frames.frameSource(2)), ...
                "predicted");

            runtime.applyInteraction("scaleReference", ...
                "interactionChanged", [10 10; 30 10]);
            runtime.applyControlValue("scaleReferenceLength", 2);
            runtime.applyControlValue("scaleCalibrationUnit", "mm");
            runtime.applyControlValue("scaleBarLength", 5);
            runtime.invokeAction("placeScaleBar");
            testCase.verifyTrue( ...
                runtime.State.project.annotations.calibration.isCalibrated);
            testCase.verifyNotEmpty(runtime.State.session.view.scaleBar);

            runtime.applyControlValue("coordinateEndFrame", 1);
            runtime.invokeAction("exportCoordinateCsv");
            testCase.verifyTrue(isfile(coordinatePath));
            testCase.verifyTrue(isfile(fullfile( ...
                folder, "video_marker_coordinates.labkit.json")));
            testCase.verifyNotEmpty( ...
                runtime.State.project.results.coordinateManifestPath);
            runtime.invokeAction("saveRecovery");
            testCase.verifyTrue(isfile( ...
                video_marker.autosave.filePath(videoPath)));

            projectPath = fullfile(folder, "video-marker-project.mat");
            runtime.saveProject(runtime.State, projectPath);
            runtime.applyFileSelection( ...
                "videoFile", strings(1, 0), zeros(1, 0));
            testCase.verifyEmpty(runtime.State.session.cache.currentImage);
            runtime.restoreProject(projectPath);
            testCase.verifyEqual( ...
                runtime.State.session.selection.currentFrame, 2);
            testCase.verifyEqual(video_marker.frameAnnotations.framePoints( ...
                runtime.State.project.annotations.frames, 1), points);
            clear runtimeCleanup folderCleanup
        end
    end
end

function writeSyntheticVideo(filepath)
writer = VideoWriter(char(filepath), "Motion JPEG AVI");
writer.FrameRate = 10;
open(writer);
cleanup = onCleanup(@() close(writer));
for k = 1:6
    [x, y] = meshgrid(1:96, 1:72);
    frame = uint8(80 + 35 .* sin((x + 2 * k) ./ 7) + ...
        30 .* cos((y - k) ./ 6));
    frame = repmat(frame, 1, 1, 3);
    writeVideo(writer, frame);
end
clear cleanup
end

function removeTempFolder(folder)
if exist(folder, "dir") == 7
    rmdir(folder, "s");
end
end
