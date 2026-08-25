classdef CommittedFrameNavigationSpec < matlab.unittest.TestCase
    %COMMITTEDFRAMENAVIGATIONSPEC Specify quiet committed frame navigation.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function provesCommittedFrameNavigation(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            project = testfixtures.video_marker.project(string(folder));
            definition = video_marker.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createHeadlessRuntime( ...
                definition, project, struct(), journal);
            cleanup = onCleanup(@() runtime.close());
            firstImage = runtime.State.session.cache.currentImage;

            runtime.applyControlValue("currentFrame", 3);

            testCase.verifyEqual( ...
                runtime.State.session.selection.currentFrame, 3);
            testCase.verifyEqual(runtime.State.session.cache.frameIndex, 3);
            testCase.verifyNotEqual( ...
                runtime.State.session.cache.currentImage, firstImage);
            events = runtime.diagnosticSnapshot().events;
            testCase.verifyFalse(any(startsWith( ...
                string({events.eventName}), ...
                "video_marker.framenavigation.changeframe.")));
            clear cleanup
        end
    end
end
