classdef Mark10ConnectionSpec < matlab.unittest.TestCase
    %MARK10CONNECTIONSPEC Specify non-probing serial-choice refresh behavior.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function refreshesPortChoicesWithoutConnecting(testCase)
            app = mark10_monitor.definition();
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            journal = labkittest.temporarySessionJournal(app, folder);
            runtime = labkittest.createHeadlessRuntime(app, [], struct(), journal);
            cleanup = onCleanup(@() runtime.close());

            runtime.invokeAction("refreshPorts");

            testCase.verifyFalse(runtime.State.session.connection.connected);
            testCase.verifyTrue(isstring(runtime.State.session.connection.ports));
            clear cleanup
        end

        function connectRequiresAnExplicitPortAndReportsTheUserFailure(testCase)
            alert = containers.Map("KeyType", "char", "ValueType", "any");
            alert("message") = "";
            context = labkittest.createCallbackContext(struct( ...
                "alert", @(message, ~) captureAlert(alert, message)));
            state = struct("session", struct("connection", struct( ...
                "selectedPort", "", "connected", false, "status", "", ...
                "lastFailure", "")));

            state = mark10_monitor.connection.connectDevice(state, context);

            testCase.verifyFalse(state.session.connection.connected);
            testCase.verifyEqual(alert("message"), ...
                "Select a serial port first.");
        end

        function disconnectRetainsValidSamplesAndReleasesResources(testCase)
            resources = containers.Map("KeyType", "char", "ValueType", "any");
            buffer = containers.Map("KeyType", "char", "ValueType", "any");
            buffer("valid") = [true; false; true];
            resources("mark10Buffer") = buffer;
            resources("mark10Sampler") = "sampler";
            resources("mark10Connection") = "connection";
            context = labkittest.createCallbackContext(struct( ...
                "getResource", @(id) resources(char(id)), ...
                "removeResource", @(id) removeResource(resources, id)));
            state = struct("session", struct( ...
                "connection", struct("connected", true, "status", ""), ...
                "acquisition", struct("monitoring", true, ...
                    "retainedValidCount", 0), ...
                "export", struct("status", "")));

            state = mark10_monitor.connection.disconnectDevice(state, context);

            testCase.verifyFalse(state.session.connection.connected);
            testCase.verifyFalse(state.session.acquisition.monitoring);
            testCase.verifyEqual( ...
                state.session.acquisition.retainedValidCount, 2);
            testCase.verifySubstring(state.session.export.status, ...
                "2 valid monitoring samples retained");
            testCase.verifyFalse(isKey(resources, "mark10Sampler"));
            testCase.verifyFalse(isKey(resources, "mark10Connection"));
        end
    end
end

function alert = captureAlert(alert, message)
alert("message") = string(message);
end

function removeResource(resources, id)
key = char(id);
if isKey(resources, key)
    remove(resources, key);
end
end
