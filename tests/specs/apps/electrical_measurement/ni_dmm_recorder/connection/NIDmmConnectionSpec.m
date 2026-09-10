classdef NIDmmConnectionSpec < matlab.unittest.TestCase
    %NIDMMCONNECTIONSPEC Specify non-opening runtime checks and disconnected state.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function discoversResourcesWithoutOpeningHardware(testCase)
            state = initialState(testCase);
            context = labkittest.createCallbackContext(struct( ...
                "log", @(varargin) [], "alert", @(varargin) []));
            state = ni_dmm_recorder.connection.refreshDevices(state, context);
            status = labkit.nidmm.availability();
            testCase.verifyEqual(state.session.connection.available, ...
                status.Available);
            testCase.verifyFalse(state.session.connection.connected);
            if status.Available
                try
                    devices = labkit.nidmm.discover();
                    testCase.verifyEqual(string( ...
                        {state.session.connection.devices.Resource}), ...
                        string({devices.Resource}));
                catch cause
                    testCase.verifyTrue(any(string(cause.identifier) == ...
                        ["labkit:nidmm:DiscoveryUnavailable", ...
                        "labkit:nidmm:DiscoveryFailed"]));
                    testCase.verifyEmpty(state.session.connection.devices);
                end
            else
                testCase.verifyEmpty(state.session.connection.devices);
                testCase.verifyEqual(state.session.connection.resource, "");
            end

            state.session.connection.connected = true;
            context = labkittest.createCallbackContext(struct( ...
                "removeResource", @(~) []));
            state = ni_dmm_recorder.connection.disconnectDevice(state, context);
            testCase.verifyFalse(state.session.connection.connected);
            testCase.verifyEqual(state.session.connection.device, "Not connected");
        end
    end
end

function state = initialState(testCase)
observed = containers.Map("KeyType", "char", "ValueType", "any");
context = labkittest.createCallbackContext(struct( ...
    "setResource", @(id, value, cleanup) capture( ...
        observed, id, value, cleanup)));
state = ni_dmm_recorder.createSession(context, struct());
testCase.verifyEqual(observed("id"), "nidmmBuffer");
end

function observed = capture(observed, id, value, cleanup)
observed("id") = id;
observed("value") = value;
observed("cleanup") = cleanup;
end
