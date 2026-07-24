classdef VideoMarkerProjectSpec < matlab.unittest.TestCase
    %VIDEOMARKERPROJECTSPEC Specify durable video annotation projects.

    methods (Test, TestTags = {'Contract:persistence', 'Env:headless'})
        function createsAValidEmptyProjectAndMigratesVideoMetadata(testCase)
            spec = video_marker.projectSpec();
            project = spec.Create();
            project.annotations.skeleton = video_marker.skeletonDefinition.fromText("hip", "");
            project.annotations.frames = video_marker.frameAnnotations.emptyAnnotations(3, 1);
            project.inputs = rmfield(project.inputs, "videoMetadata");

            migrated = spec.Migrate(project, 1);

            testCase.verifyTrue(spec.Validate(migrated));
            testCase.verifyEqual(migrated.inputs.videoMetadata.frameCount, 3);
        end

        function upgradesAnnotationSourcesAndRejectsWrongVideoFrameCounts(testCase)
            legacy = struct("schemaVersion", 1, "coords", NaN(3, 1, 2), ...
                "frameStatus", uint8([2; 1; 0]));
            annotations = video_marker.frameAnnotations.upgradeAnnotationSchema(legacy);
            spec = video_marker.projectSpec();
            project = spec.Create();
            project.annotations.skeleton = video_marker.skeletonDefinition.fromText( ...
                "hip, foot", "hip-foot");
            project.annotations.frames = video_marker.frameAnnotations.emptyAnnotations(3, 2);
            project.inputs.videoMetadata.frameCount = 2;

            testCase.verifyEqual(annotations.schemaVersion, 2);
            testCase.verifyEqual(annotations.frameSource, uint8([1; 2; 0]));
            testCase.verifyEqual(annotations.trackingConfidence(1), 1);
            testCase.verifyTrue(isnan(annotations.trackingConfidence(2)));
            testCase.verifyError(@() spec.Validate(project), "video_marker:InvalidProject");
        end

        function importsTheDeclaredLegacyProjectWithoutRetainingLegacyFields(testCase)
            legacy = struct( ...
                "schemaVersion", 1, ...
                "videoPath", "/missing/sample.avi", ...
                "videoReference", struct("schemaVersion", 1, ...
                    "relativePath", "../media/sample.avi", ...
                    "originalPath", "/missing/sample.avi", "fileName", "sample.avi"), ...
                "skeleton", video_marker.skeletonDefinition.fromParts(["hip"; "knee"], [1 2]), ...
                "annotations", video_marker.frameAnnotations.emptyAnnotations(2, 2), ...
                "calibration", labkit.app.interaction.scaleCalibration(20, 2, "mm"), ...
                "exportPreferences", struct("unitMode", "calibrated_physical", ...
                    "originMode", "first_point", "yAxisMode", "up", ...
                    "startFrame", 1, "endFrame", 2), ...
                "currentFrame", 2);
            legacy.annotations = video_marker.frameAnnotations.setFramePoints( ...
                legacy.annotations, 1, [10 20; 30 40], "confirmed");

            [project, resume] = video_marker.projectSpec().LegacyImports.videoMarkerProject(legacy);

            testCase.verifyTrue(video_marker.projectSpec().Validate(project));
            testCase.verifyEqual(project.inputs.sources.reference, legacy.videoReference);
            testCase.verifyEqual(project.annotations.frames.coords, legacy.annotations.coords);
            testCase.verifyEqual(project.parameters.coordinateUnitMode, "calibrated_physical");
            testCase.verifyEqual(resume.currentFrame, 2);
            testCase.verifyFalse(isfield(project, "videoPath"));
        end
    end
end
