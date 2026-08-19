classdef VideoMarkerWorkflowSpec < matlab.unittest.TestCase
    %VIDEOMARKERWORKFLOWSPEC Specify marking, prediction, exports, restoration.

    methods (Test, TestTags = {'Contract:presentation', 'Env:headless'})
        function marksPredictsExportsAndRestoresSyntheticVideo(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            context = labkit.app.synthetic.Context(folder);
            pack = video_marker.syntheticInputs.writeSamplePack(context);
            markerPath = context.outputPath("markers.csv");
            coordinatePath = context.outputPath("coordinates.csv");
            annotatedVideoPath = context.outputPath("annotated.mp4");
            backend = struct( ...
                "chooseOutputFile", @(~, defaultPath) chooseOutput( ...
                    defaultPath, markerPath, coordinatePath, ...
                    annotatedVideoPath), ...
                "inform", @(~, ~) [], ...
                "alert", @(~, ~) []);
            definition = video_marker.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createHeadlessRuntime( ...
                definition, pack.InitialProject, backend, ...
                journal);
            cleanup = onCleanup(@() runtime.close());

            points = [24 34; 32 38; 40 42; 48 46; 56 50];
            videoPath = ...
                pack.InitialProject.inputs.sources(1).reference.originalPath;
            autosavePath = video_marker.autosave.filePath(videoPath);
            testCase.verifyFalse(isfile(autosavePath));
            runtime.applyInteraction("framePoints", "interactionChanged", points);
            testCase.verifyTrue(isfile(autosavePath));
            autosave = load(autosavePath, "labkitProject");
            testCase.verifyEqual( ...
                video_marker.frameAnnotations.framePoints( ...
                    autosave.labkitProject.payload.annotations.frames, 1), ...
                points);
            runtime.invokeAction("nextFrame");
            autosave = load(autosavePath, "labkitProject");
            testCase.verifyEqual(video_marker.frameAnnotations.sourceName( ...
                autosave.labkitProject.payload.annotations.frames.frameSource(2)), ...
                "predicted");
            runtime.invokeAction("measureScaleReference");
            runtime.applyInteraction("scaleReference", "interactionChanged", [10 10; 30 10]);
            runtime.applyControlValue("scaleReferenceLength", 2);
            runtime.applyControlValue("scaleCalibrationUnit", "mm");
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
            testCase.verifyTrue(isfile(runtime.State.project.results.markerManifestPath));
            testCase.verifyTrue(isfile(runtime.State.project.results.coordinateManifestPath));
            saved = fullfile(folder, "video-marker-project.mat");
            runtime.saveProject(runtime.State, saved);
            runtime.restoreProject(saved);
            testCase.verifyEqual(video_marker.frameAnnotations.framePoints( ...
                runtime.State.project.annotations.frames, 1), points);
            clear cleanup
        end

        function rendersAfterRestoringRuntimeNamedAutosave(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            context = labkit.app.synthetic.Context(folder);
            pack = video_marker.syntheticInputs.writeSamplePack(context);
            project = pack.InitialProject;
            project.inputs.sources(1).id = "video-1";
            markerPath = fullfile(folder, "autosave-markers.csv");
            coordinatePath = fullfile(folder, "autosave-coordinates.csv");
            annotatedVideoPath = fullfile(folder, "autosave-annotated.mp4");
            namedProjectPath = fullfile(folder, "named-project.mat");
            videoPath = project.inputs.sources(1).reference.originalPath;
            expectedOutputFolder = fullfile(fileparts(videoPath), ...
                "video_marker");
            backend = struct( ...
                "chooseOutputFile", @(~, defaultPath) ...
                    chooseRestoredOutput(defaultPath, ...
                    expectedOutputFolder, markerPath, coordinatePath, ...
                    annotatedVideoPath), ...
                "inform", @(~, ~) [], ...
                "alert", @(~, ~) []);
            definition = video_marker.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createHeadlessRuntime( ...
                definition, project, backend, journal);
            cleanup = onCleanup(@() runtime.close());
            points = [24 34; 32 38; 40 42; 48 46; 56 50];

            runtime.applyInteraction( ...
                "framePoints", "interactionChanged", points);
            autosavePath = video_marker.autosave.filePath(videoPath);
            runtime.restoreProject(autosavePath);
            runtime.invokeAction("nextFrame");
            runtime.invokeAction("exportMarkerCsv");
            runtime.applyControlValue("coordinateEndFrame", 1);
            runtime.invokeAction("exportCoordinateCsv");
            if ismac || ispc
                runtime.invokeAction("exportAnnotatedVideo");
            end
            runtime.saveProject(runtime.State, namedProjectPath);
            runtime.restoreProject(namedProjectPath);

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

function choice = chooseRestoredOutput(defaultPath, expectedFolder, ...
        markerPath, coordinatePath, annotatedVideoPath)
defaultPath = string(defaultPath);
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
        annotatedVideoPath)
if contains(string(defaultPath), "markers", IgnoreCase=true)
    choice = labkit.app.dialog.Choice(markerPath);
elseif contains(string(defaultPath), "annotated", IgnoreCase=true)
    choice = labkit.app.dialog.Choice(annotatedVideoPath);
else
    choice = labkit.app.dialog.Choice(coordinatePath);
end
end
