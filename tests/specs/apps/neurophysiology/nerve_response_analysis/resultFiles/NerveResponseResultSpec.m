classdef NerveResponseResultSpec < matlab.unittest.TestCase
    %NERVERESPONSERESULTSPEC Specify JSON-safe analysis result packaging.

    methods (Test, TestTags = {'Contract:result', 'Env:headless'})
        function convertsTablesToJsonSafeRowsAndAddsExporterIdentity(testCase)
            analysis = struct("events", table([1; 2], ["stim"; "stim"], ...
                'VariableNames', {'sampleIndex', 'source'}), ...
                "trains", table(), "metrics", table(), "issues", table());

            payload = nerve_response_analysis.resultFiles.analysisJsonStruct(analysis);

            testCase.verifyTrue(isstruct(payload.events));
            testCase.verifyEqual(numel(payload.events), 2);
            testCase.verifyEqual(string(payload.events(1).source), "stim");
            testCase.verifyEqual(payload.exportedBy, "labkit_NerveResponseAnalysis_app");
        end
    end
end
