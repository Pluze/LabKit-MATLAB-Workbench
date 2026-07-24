classdef VideoMarkerResultSpec < matlab.unittest.TestCase
    %VIDEOMARKERRESULTSPEC Specify portable marker and coordinate exports.

    methods (Test, TestTags = {'Contract:result', 'Env:headless'})
        function exportsCalibratedCoordinatesWithAFirstPointOrigin(testCase)
            skeleton = video_marker.skeletonDefinition.fromText("hip, knee", "hip-knee");
            annotations = video_marker.frameAnnotations.emptyAnnotations(2, 2);
            annotations = video_marker.frameAnnotations.setFramePoints( ...
                annotations, 1, [11 21; 31 41], "confirmed");
            annotations = video_marker.frameAnnotations.setFramePoints( ...
                annotations, 2, [13 25; 35 45], "confirmed");
            video = struct("frameRate", 10);
            calibration = labkit.app.interaction.scaleCalibration(20, 2, "mm");
            options = video_marker.coordinateExport.options( ...
                "startFrame", 1, "endFrame", 2, ...
                "unitMode", "calibrated_physical", ...
                "originMode", "first_point", "yAxisMode", "up");

            tableValue = video_marker.coordinateExport.buildTable( ...
                annotations, skeleton, video, calibration, options);

            testCase.verifyEqual(tableValue.hip__x, [0; .2], AbsTol=1e-12);
            testCase.verifyEqual(tableValue.hip__y, [0; -.4], AbsTol=1e-12);
            testCase.verifyEqual(tableValue.knee__x, [2; 2.4], AbsTol=1e-12);
            testCase.verifyEqual(tableValue.coordinate_unit, ["mm"; "mm"]);
        end

        function markerCsvRoundTripPreservesSkeletonAndFrameProvenance(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            skeleton = video_marker.skeletonDefinition.fromText( ...
                "hip, knee", "hip-knee");
            annotations = video_marker.frameAnnotations.emptyAnnotations(2, 2);
            annotations = video_marker.frameAnnotations.setFramePoints( ...
                annotations, 1, [10 20; 30 40], "confirmed");
            path = fullfile(folder, "markers.csv");
            video = struct("path", "synthetic.avi", "frameCount", 2, ...
                "frameRate", 10, "duration", .2, "height", 72, "width", 96);

            video_marker.markerCsv.writeFile(path, annotations, skeleton, video, ...
                labkit.app.interaction.scaleCalibration(40, 2, "mm"));
            payload = video_marker.markerCsv.readFile(path);

            testCase.verifyEqual(payload.skeleton.pointNames, ["hip"; "knee"]);
            testCase.verifyEqual(payload.annotations.coords, annotations.coords);
            testCase.verifyEqual(payload.annotations.frameStatus, annotations.frameStatus);
            testCase.verifyEqual(payload.annotations.frameSource, annotations.frameSource);
            testCase.verifyEqual(payload.annotations.trackingConfidence, ...
                annotations.trackingConfidence, AbsTol=1e-12);
        end
    end
end
