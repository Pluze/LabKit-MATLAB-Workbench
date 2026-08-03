classdef SessionLoggingPrivacyContractSpec < matlab.unittest.TestCase
    %SESSIONLOGGINGPRIVACYCONTRACTSPEC Freeze full-detail logging boundary.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function passesCompleteDetailsToTheLoggingBackend(testCase)
            captured = cell(1, 7);
            context = labkit.app.internal.runtime.CallbackContextFactory.create( ...
                struct("log", @captureLog));
            syntheticPath = "/synthetic/input.csv";

            context.log("info", "source.loaded", ...
                "Loaded " + syntheticPath + ".", Category="sourceFiles", ...
                Audience="developer", ...
                Attributes=struct("sourcePath", syntheticPath, ...
                    "values", [1 2 3]));

            testCase.verifyEqual(captured{3}, ...
                "Loaded /synthetic/input.csv.");
            testCase.verifyEqual(captured{6}.sourcePath, syntheticPath);
            testCase.verifyEqual(captured{6}.values, [1 2 3]);

            function captureLog(varargin)
                captured = varargin;
            end
        end
    end
end
