classdef AppIdentityContractTest < matlab.unittest.TestCase
    %APPIDENTITYCONTRACTTEST Protect stable globally unique runtime app ids.

    methods (Test, TestTags = {'Integration', 'Style'})
        function publicDefinitionsDeclareUniqueStableIds(testCase)
            root = setupLabKitTestPath();
            catalog = jsondecode(fileread(fullfile( ...
                root, "docs", "catalogs", "apps.json")));
            apps = catalog.apps;
            ids = strings(numel(apps), 1);
            for k = 1:numel(apps)
                folder = fullfile(root, string(apps(k).folder));
                definitions = dir(fullfile(folder, "+*", "definition.m"));
                testCase.assertNumElements(definitions, 1, ...
                    "Each cataloged app must own one package definition.");
                source = fileread(fullfile( ...
                    definitions(1).folder, definitions(1).name));
                token = regexp(source, ...
                    '["'']Id["'']\s*,\s*["'']([A-Za-z][A-Za-z0-9_.-]*)["'']', ...
                    "tokens", "once");
                testCase.assertNotEmpty(token, ...
                    "App definition must declare one literal stable Id.");
                ids(k) = string(token{1});
            end
            testCase.verifyEqual(numel(unique(ids, 'stable')), numel(ids), ...
                "Runtime app Id values must be globally unique.");
        end
    end
end
