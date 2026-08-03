classdef NerveResponseSourceSpec < matlab.unittest.TestCase
    %NERVERESPONSESOURCESPEC Specify cleared source selection state.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function clearingASelectionLeavesAnExplicitReaderFacingAction(testCase)
            state = struct("session", struct("workflow", ...
                struct("lastAction", "Selected filter record", "statusMessage", "ready")));
            selection = labkit.app.event.ListSelection();
            context = labkit.app.internal.runtime.CallbackContextFactory.disconnected();

            actual = nerve_response_analysis.sourceFiles.filterChanged(state, selection, context);

            testCase.verifyEqual(actual.session.workflow.lastAction, "Cleared filter record");
        end
    end
end
