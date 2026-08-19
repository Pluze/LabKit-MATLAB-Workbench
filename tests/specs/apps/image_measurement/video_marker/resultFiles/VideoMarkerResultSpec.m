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

        function rendersEveryFrameWithPixelSpaceLandmarks(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            context = labkit.app.synthetic.Context(folder);
            pack = video_marker.syntheticInputs.writeSamplePack(context);
            sourcePath = ...
                pack.InitialProject.inputs.sources(1).reference.originalPath;
            outputPath = fullfile(folder, "annotated.mp4");
            project = pack.InitialProject;
            project.annotations.frames = ...
                video_marker.frameAnnotations.setFramePoints( ...
                project.annotations.frames, 1, ...
                [24 34; 32 38; 40 42; 48 46; 56 50], "confirmed");
            events = cell(0, 3);

            if ~(ismac || ispc)
                testCase.verifyError(@() ...
                    video_marker.resultFiles.writeAnnotatedVideo( ...
                    sourcePath, outputPath, project.annotations.frames, ...
                    project.annotations.skeleton, @recordProgress), ...
                    "video_marker:Mpeg4Unavailable");
                return
            end

            summary = video_marker.resultFiles.writeAnnotatedVideo( ...
                sourcePath, outputPath, project.annotations.frames, ...
                project.annotations.skeleton, @recordProgress);

            source = VideoReader(sourcePath);
            rendered = VideoReader(outputPath);
            sourceFrame = readFrame(source);
            renderedFrame = readFrame(rendered);
            testCase.verifyTrue(isfile(outputPath));
            testCase.verifyEqual(summary.frameCount, 6);
            testCase.verifyEqual(summary.frameRate, source.FrameRate, ...
                AbsTol=1e-12);
            testCase.verifySize(renderedFrame, size(sourceFrame));
            testCase.verifyGreaterThan( ...
                max(abs(double(renderedFrame(:)) - ...
                double(sourceFrame(:)))), 20);
            testCase.verifyEqual(events{1, 1}, "started");
            testCase.verifyEqual(events{end, 1}, "completed");
            testCase.verifyEqual(events{end, 2}, 6);

            function recordProgress(stage, completed, total)
                events(end + 1, :) = {stage, completed, total};
            end
        end
    end
end
