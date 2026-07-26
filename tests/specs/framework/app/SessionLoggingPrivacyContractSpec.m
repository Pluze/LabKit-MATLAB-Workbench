classdef SessionLoggingPrivacyContractSpec < matlab.unittest.TestCase
    %SESSIONLOGGINGPRIVACYCONTRACTSPEC Freeze App-facing retained-data privacy rules.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function rejectsRawPathsBeforeInvokingAnyLoggingBackend(testCase)
            context = labkit.app.internal.CallbackContextFactory.disconnected();
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            syntheticPath = string(fullfile(folder, "input.csv"));

            testCase.verifyError(@() context.log("info", "source.loaded", ...
                "Loaded " + syntheticPath + ".", ...
                Category="sourceFiles"), "labkit:app:contract:UnsafeLogData");
        end

        function rejectsRawFilenamesInAttributesBeforeInvokingAnyLoggingBackend(testCase)
            context = labkit.app.internal.CallbackContextFactory.disconnected();
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            syntheticPath = string(fullfile(folder, "input.csv"));

            testCase.verifyError(@() context.log("info", "source.loaded", ...
                "Selected source loaded.", Category="sourceFiles", ...
                Attributes=struct("sourcePath", syntheticPath)), ...
                "labkit:app:contract:UnsafeLogData");
        end
    end
end
