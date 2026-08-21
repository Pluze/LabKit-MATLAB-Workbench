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
            if ~isempty(definition.Requirements)
                testCase.verifyTrue(labkit.contract.checkRequirements( ...
                    definition.Requirements).ok);
            end
        end

        function declaresEveryCalledLabKitFacade(testCase, App)
            definition = feval(char(App.Package + ".definition"));
            declared = strings(1, 0);
            if ~isempty(definition.Requirements)
                declared = string({definition.Requirements.facades.facade});
            end
            files = dir(fullfile(App.Folder, "**", "*.m"));
            source = "";
            for index = 1:numel(files)
                source = source + newline + string(fileread( ...
                    fullfile(files(index).folder, files(index).name)));
            end
            facades = ["image", "thermal", "dta", ...
                "rhs", "biosignal", "mark10"];
            called = facades(arrayfun(@(name) contains( ...
                source, "labkit." + name + "."), facades));

            testCase.verifyTrue(all(ismember(called, declared)), ...
                "App calls undeclared LabKit facade(s): " + ...
                strjoin(setdiff(called, declared), ", ") + ".");
        end

        function declaresUnambiguousFileCollectionControls(testCase, App)
            definition = feval(char(App.Package + ".definition"));
            plan = labkittest.inspectDefinition( ...
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

        function createsAndPresentsTheInitialSessionHeadlessly(testCase, App)
            definition = feval(char(App.Package + ".definition"));
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createHeadlessRuntime( ...
                definition, [], struct(), journal);
            cleanup = onCleanup(@() runtime.close());

            testCase.verifyFalse(runtime.StartupFailed, ...
                "Initial App presentation failed: " + App.Package);
            testCase.verifyTrue(isstruct(runtime.State));
            clear cleanup
        end

    end
end
