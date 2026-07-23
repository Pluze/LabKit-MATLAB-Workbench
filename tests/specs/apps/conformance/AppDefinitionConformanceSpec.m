classdef AppDefinitionConformanceSpec < matlab.unittest.TestCase
    %APPDEFINITIONCONFORMANCESPEC Verify every public App definition contract.

    properties (TestParameter)
        App = labkittest.publicApps()
    end

    methods (Test, TestTags = {'Contract:definition', 'Env:headless'})
        function declaresThePublicAppContract(testCase, App)
            definition = feval(char(App.Package + ".definition"));

            testCase.verifyEqual(string(definition.AppId), App.Package);
            testCase.verifyEqual(string(definition.Entrypoint), App.Entrypoint);
            testCase.verifyNotEmpty(regexp(string(definition.AppVersion), ...
                '^\d+\.\d+\.\d+$', "once"));
            testCase.verifyTrue(labkit.contract.checkRequirements( ...
                definition.Requirements).ok);
        end
    end
end
