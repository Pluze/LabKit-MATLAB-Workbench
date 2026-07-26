classdef SessionLoggingPrivacyContractSpec < matlab.unittest.TestCase
    %SESSIONLOGGINGPRIVACYCONTRACTSPEC Freeze App-facing retained-data privacy rules.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function rejectsRawPathsBeforeInvokingAnyLoggingBackend(testCase)
            context = labkit.app.internal.CallbackContextFactory.disconnected();

            testCase.verifyError(@() context.log("info", "source.loaded", ...
                "Loaded C:\\unsafe\\input.csv.", ...
                Category="runtime.source"), "labkit:app:contract:UnsafeLogData");
        end

        function rejectsRawFilenamesInAttributesBeforeInvokingAnyLoggingBackend(testCase)
            context = labkit.app.internal.CallbackContextFactory.disconnected();

            testCase.verifyError(@() context.log("info", "source.loaded", ...
                "Selected source loaded.", Category="runtime.source", ...
                Attributes=struct("sourceName", "input.csv")), ...
                "labkit:app:contract:UnsafeLogData");
        end
    end
end
