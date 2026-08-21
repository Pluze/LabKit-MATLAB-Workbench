classdef NerveResponseStateSpec < matlab.unittest.TestCase
    %NERVERESPONSESTATESPEC Specify current role-identified sources.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function createsCurrentSourceDefaults(testCase)
            project = nerve_response_analysis.initialData();
            testCase.verifyEmpty(project.inputs.sources);
        end
    end
end
