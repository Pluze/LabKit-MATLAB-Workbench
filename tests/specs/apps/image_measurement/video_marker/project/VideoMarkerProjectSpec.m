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
    end
end
