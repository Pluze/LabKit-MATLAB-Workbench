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

        function declaresUnambiguousFileCollectionControls(testCase, App)
            definition = feval(char(App.Package + ".definition"));
            plan = labkit.app.internal.DefinitionInspector.platformPlan( ...
                definition);
            nodes = plan.Nodes(string({plan.Nodes.Kind}) == "fileList");

            for index = 1:numel(nodes)
                config = nodes(index).Configuration;
                if config.MaxFiles ~= 1
                    testCase.verifyEqual(config.SelectionMode, "multiple", ...
                        "Multi-file collection must support file multi-selection: " + ...
                        App.Package + "." + nodes(index).Id);
                end
                testCase.verifyFalse(contains(lower(config.ChooseLabel), ...
                    ["folder", "directory"]), ...
                    "The file button must not duplicate the separate folder controls: " + ...
                    App.Package + "." + nodes(index).Id);
            end
        end
    end
end
