classdef VideoMarkerWorkflowSpec < matlab.unittest.TestCase
    %VIDEOMARKERWORKFLOWSPEC Specify marking, prediction, exports, restoration.

    methods (Test, TestTags = {'Contract:presentation', 'Env:hidden-gui'})
        function marksPredictsExportsAndRestoresSyntheticVideo(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            context = labkit.app.synthetic.Context(folder);
            pack = video_marker.syntheticInputs.writeSamplePack(context);
            markerPath = context.outputPath("markers.csv");
            coordinatePath = context.outputPath("coordinates.csv");
            backend = struct( ...
                "chooseOutputFile", @(~, defaultPath) chooseOutput( ...
                    defaultPath, markerPath, coordinatePath), ...
                "alert", @(~, ~) []);
            definition = video_marker.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkit.app.internal.RuntimeFactory.createMatlab( ...
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

            testCase.verifyEqual(video_marker.frameAnnotations.sourceName( ...
                runtime.State.project.annotations.frames.frameSource(2)), "predicted");
            testCase.verifyTrue(runtime.State.project.annotations.calibration.isCalibrated);
            testCase.verifyTrue(isfile(markerPath));
            testCase.verifyTrue(isfile(coordinatePath));
            testCase.verifyTrue(isfile(runtime.State.project.results.markerManifestPath));
            testCase.verifyTrue(isfile(runtime.State.project.results.coordinateManifestPath));
            saved = fullfile(folder, "video-marker-project.mat");
            runtime.saveProject(runtime.State, saved);
            runtime.restoreProject(saved);
            testCase.verifyEqual(video_marker.frameAnnotations.framePoints( ...
                runtime.State.project.annotations.frames, 1), points);
            clear cleanup
        end
    end
end

function choice = chooseOutput(defaultPath, markerPath, coordinatePath)
if contains(string(defaultPath), "markers", IgnoreCase=true)
    choice = labkit.app.dialog.Choice(markerPath);
else
    choice = labkit.app.dialog.Choice(coordinatePath);
end
end
