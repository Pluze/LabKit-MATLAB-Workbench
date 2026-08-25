classdef CommittedCalibrationSpec < matlab.unittest.TestCase
    %COMMITTEDCALIBRATIONSPEC Specify quiet committed calibration updates.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function provesCommittedCalibration(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            definition = curvature.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createHeadlessRuntime( ...
                definition, [], struct(), journal);
            cleanup = onCleanup(@() runtime.close());

            runtime.applyControlValue("scaleReferencePixels", 24);
            runtime.applyControlValue("scaleReferenceLength", 6);
            runtime.applyControlValue("scaleBarLength", 50);

            calibration = ...
                runtime.State.project.annotations.calibration;
            testCase.verifyEqual(calibration.referencePixels, 24);
            testCase.verifyEqual(calibration.referenceLength, 6);
            testCase.verifyEqual( ...
                runtime.State.project.parameters.scaleBarLength, 50);
            testCase.verifyEmpty(runtime.State.session.view.scaleBar);
            events = runtime.diagnosticSnapshot().events;
            testCase.verifyFalse(any(startsWith( ...
                string({events.eventName}), ...
                "curvature.scalecalibration.")));
            clear cleanup
        end
    end
end
