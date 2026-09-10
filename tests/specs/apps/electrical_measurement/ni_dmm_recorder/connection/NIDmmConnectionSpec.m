classdef NIDmmConnectionSpec < matlab.unittest.TestCase
    %NIDMMCONNECTIONSPEC Specify non-opening runtime checks and disconnected state.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function reportsAvailabilityWithoutOpeningHardware(testCase)
            state = initialState(testCase);
            state = ni_dmm_recorder.connection.refreshAvailability(state, []);
            status = labkit.nidmm.availability();
            testCase.verifyEqual(state.session.connection.available, ...
                status.Available);
            testCase.verifyEqual(state.session.connection.status, status.Message);
            testCase.verifyFalse(state.session.connection.connected);

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
