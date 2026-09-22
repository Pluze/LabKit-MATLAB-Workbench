classdef EisSessionViewSpec < matlab.unittest.TestCase
    %EISSESSIONVIEWSPEC Keep overview and custom viewport resets independent.

    methods (Test, TestTags = {'Contract:state', 'Env:headless'})
        function overviewResetAdvancesOnlyItsViewRevision(testCase)
            definition = eis.definition();
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            journal = labkittest.temporarySessionJournal(definition, root);
            runtime = labkittest.createHeadlessRuntime( ...
                definition, [], struct(), journal);
            cleanup = onCleanup(@() runtime.close());
            initial = runtime.State;

            runtime.invokeAction("fitOverviewAxes");
            afterFirst = runtime.State;
            testCase.verifyEqual(afterFirst.session.cache.overviewViewRevision, 1);
            testCase.verifyEqual(afterFirst.session.cache.plotViewRevision, ...
                initial.session.cache.plotViewRevision);
            testCase.verifyEqual(afterFirst.project, initial.project);

            runtime.invokeAction("fitOverviewAxes");
            testCase.verifyEqual(runtime.State.session.cache.overviewViewRevision, 2);
            clear cleanup
        end
    end
end
