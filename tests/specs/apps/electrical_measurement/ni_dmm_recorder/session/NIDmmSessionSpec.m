classdef NIDmmSessionSpec < matlab.unittest.TestCase
    % NIDMMSESSIONSPEC Invariant: the App creates only transient device, configuration, acquisition, and export state.

    methods (Test, TestTags = {'Contract:state', 'Env:headless'})
        function provesNIDmmSession(testCase)
            observed = containers.Map("KeyType", "char", "ValueType", "any");
            context = labkittest.createCallbackContext(struct( ...
                "setResource", @(id, value, cleanup) capture( ...
                    observed, id, value, cleanup)));
            state = ni_dmm_recorder.createSession(context, struct());
            testCase.verifyFalse(state.session.connection.connected);
            testCase.verifyEqual(state.session.configuration.mode, ...
                "4-Wire Resistance");
            testCase.verifyEqual(state.session.configuration.rate, "30 Hz");
            testCase.verifyEqual(observed("id"), "nidmmBuffer");
            testCase.verifyClass(observed("value"), "containers.Map");
        end
    end
end

function observed = capture(observed, id, value, cleanup)
observed("id") = id;
observed("value") = value;
observed("cleanup") = cleanup;
end
