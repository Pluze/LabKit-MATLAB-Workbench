classdef NIDmmRecordingSpec < matlab.unittest.TestCase
    %NIDMMRECORDINGSPEC Specify native launch and supported connection failure.

    methods (Test, TestTags = {'Contract:workflow', 'Env:hidden-gui'})
        function launchesChecksDriverAndHandlesInvalidResource(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            alerts = containers.Map("KeyType", "char", "ValueType", "any");
            backend = struct("alert", @(message, title) ...
                captureAlert(alerts, message, title));
            definition = ni_dmm_recorder.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createMatlabRuntime( ...
                definition, [], backend, journal);
            cleanup = onCleanup(@() runtime.close());

            testCase.verifyFalse(runtime.StartupFailed);
            runtime.invokeAction("checkDriver");
            testCase.verifyNotEmpty(runtime.State.session.connection.status);
            runtime.applyControlValue("measurementMode", "2-Wire Resistance");
            runtime.applyControlValue("rangeMode", "Fixed");
            runtime.applyControlValue("fixedRange", 1000);
            runtime.applyControlValue("resolutionDigits", "5.5");
            runtime.applyControlValue("sampleRate", "30 Hz");
            runtime.applyControlValue("resourceName", "");
            runtime.invokeAction("connectDevice");
            testCase.verifyFalse(runtime.State.session.connection.connected);
            testCase.verifyEqual(alerts("title"), "NI-DMM Connection");
            testCase.verifyNotEmpty(alerts("message"));
            runtime.invokeAction("readOnce");
            runtime.invokeAction("startRecording");
            runtime.invokeAction("stopRecording");
            runtime.invokeAction("refitPlot");
            runtime.invokeAction("exportRecording");
            runtime.invokeAction("disconnectDevice");
            testCase.verifyFalse(runtime.State.session.acquisition.recording);
            clear cleanup
        end
    end
end

function alerts = captureAlert(alerts, message, title)
alerts("message") = string(message);
alerts("title") = string(title);
assert(strlength(alerts("message")) > 0);
assert(strlength(alerts("title")) > 0);
end
