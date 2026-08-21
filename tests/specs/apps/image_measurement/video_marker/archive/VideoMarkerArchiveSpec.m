classdef VideoMarkerArchiveSpec < matlab.unittest.TestCase
    %VIDEOMARKERARCHIVESPEC Specify the current App-owned MAT snapshot.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function writesAndReadsOneCurrentSnapshot(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            context = labkittest.disconnectedCallbackContext();
            project = video_marker.initialData();
            state = struct("project", project, ...
                "session", video_marker.createSession(project, context));
            filepath = fullfile(folder, "video-marker.mat");

            video_marker.archive.writeFile(state, filepath);
            restored = video_marker.archive.readFile(filepath, context);

            testCase.verifyTrue(video_marker.archive.validateProject( ...
                restored.project));
            testCase.verifyEqual(restored.project, project);
            testCase.verifyEqual(restored.session.selection.currentFrame, 1);
        end

        function rejectsWrongVideoFrameCounts(testCase)
            project = video_marker.initialData();
            project.annotations.skeleton = ...
                video_marker.skeletonDefinition.fromText( ...
                    "hip, foot", "hip-foot");
            project.annotations.frames = ...
                video_marker.frameAnnotations.emptyAnnotations(3, 2);
            project.inputs.videoMetadata.frameCount = 2;

            testCase.verifyError(@() video_marker.archive.validateProject(project), ...
                "video_marker:InvalidProject");
        end
    end
end
