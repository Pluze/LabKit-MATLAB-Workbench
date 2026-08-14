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
    end
end
