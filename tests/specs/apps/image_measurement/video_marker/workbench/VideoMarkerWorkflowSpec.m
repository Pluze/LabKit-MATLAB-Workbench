classdef VideoMarkerWorkflowSpec < matlab.unittest.TestCase
    %VIDEOMARKERWORKFLOWSPEC Specify marking, prediction, exports, restoration.

    methods (Test, TestTags = {'Contract:presentation', 'Env:hidden-gui'})
        function marksPredictsExportsAndRestoresSyntheticVideo(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            context = labkit.app.diagnostic.SampleContext(folder);
            pack = video_marker.debug.writeSamplePack(context);
            markerPath = context.outputPath("markers.csv");
            coordinatePath = context.outputPath("coordinates.csv");
            backend = struct( ...
                "chooseOutputFile", @(~, defaultPath) chooseOutput( ...
                    defaultPath, markerPath, coordinatePath), ...
                "alert", @(~, ~) []);
            runtime = labkit.app.internal.RuntimeFactory.createMatlab( ...
                video_marker.definition(), pack.InitialProject, backend);
            cleanup = onCleanup(@() runtime.close());

            points = [24 34; 32 38; 40 42; 48 46; 56 50];
            runtime.applyInteraction("framePoints", "interactionChanged", points);
            runtime.invokeAction("nextFrame");
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
