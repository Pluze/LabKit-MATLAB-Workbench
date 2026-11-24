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
            context = labkittest.createCallbackContext(struct( ...
                "getResource", @(id) resources(char(id)), ...
                "setResource", @(id,value,~) putResource(resources,id,value), ...
                "removeResource", @(id) removeResource(resources, id)));
            state = struct("session",mark10_monitor.createSession(struct(),context));
            state.session.connection.connected = true;
            state.session.acquisition.monitoring = true;
            buffer = resources("mark10Buffer");
            buffer("valid") = [true; false; true];
            buffer("time_s") = (0:2)'/50;
            buffer("force_N") = [1; NaN; 1];
            buffer("travel_mm") = [2; NaN; 2];
            resources("mark10Sampler") = "sampler";
            box = containers.Map("KeyType","char","ValueType","any");
            box("connection") = struct("AcquisitionMode","Synchronized n");
            resources("mark10Connection") = box;

            state = mark10_monitor.connection.disconnectDevice(state, context);

            testCase.verifyFalse(state.session.connection.connected);
            testCase.verifyFalse(state.session.acquisition.monitoring);
            testCase.verifyEqual( ...
                state.session.acquisition.retainedValidCount, sum(buffer("valid")));
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

function resources = putResource(resources,id,value)
resources(char(id)) = value;
end
