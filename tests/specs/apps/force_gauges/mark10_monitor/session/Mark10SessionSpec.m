classdef Mark10SessionSpec < matlab.unittest.TestCase
    %MARK10SESSIONSPEC Specify project-free transient monitor initialization.

    methods (Test, TestTags = {'Contract:state', 'Env:headless'})
        function createsTransientStateAndManagedBuffer(testCase)
            observed = containers.Map("KeyType", "char", "ValueType", "any");
            backend = struct("setResource", @(scope, id, value, cleanup) ...
                captureResource(observed, scope, id, value, cleanup));
            context = labkittest.createCallbackContext(backend);

            session = mark10_monitor.createSession(struct(), context);

            testCase.verifyFalse(session.connection.connected);
            testCase.verifyFalse(session.playback.loaded);
            testCase.verifyEqual(session.acquisition.rate, "50 Hz");
            testCase.verifyEqual(session.cache.plotViewRevision, 0);
            testCase.verifyEqual(session.cache.plotLimits.time_s, [0, 5]);
            testCase.verifyEqual(session.cache.plotLimits.force_N, [-1, 1]);
            testCase.verifyEqual(session.cache.plotLimits.travel_mm, [-10, 10]);
            testCase.verifyEqual(observed("scope"), "application");
            testCase.verifyEqual(observed("id"), "mark10Buffer");
            testCase.verifyClass(observed("value"), "containers.Map");
        end
    end
end

function captureResource(observed, scope, id, value, cleanup)
observed("scope") = scope;
observed("id") = id;
observed("value") = value;
observed("cleanup") = cleanup;
end
