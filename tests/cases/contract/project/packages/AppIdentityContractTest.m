classdef AppIdentityContractTest < matlab.unittest.TestCase
    %APPIDENTITYCONTRACTTEST Protect stable globally unique runtime app ids.

    methods (Test, TestTags = {'Integration', 'Style'})
        function publicDefinitionsDeclareUniqueStableIds(testCase)
            root = setupLabKitTestPath();
            apps = discoverLabKitApps();
            ids = strings(height(apps), 1);
            for k = 1:height(apps)
                folder = string(apps.Folder(k));
                definitions = dir(fullfile(folder, "+*", "definition.m"));
                testCase.assertNumElements(definitions, 1, ...
                    "Each discovered public app must own one package definition.");
                source = fileread(fullfile( ...
                    definitions(1).folder, definitions(1).name));
                token = regexp(source, ...
                    'AppId\s*=\s*["'']([A-Za-z][A-Za-z0-9_.-]*)["'']', ...
                    "tokens", "once");
                testCase.assertNotEmpty(token, ...
                    "App definition must declare one literal stable AppId.");
                ids(k) = string(token{1});
            end
            testCase.verifyEqual(numel(unique(ids, 'stable')), numel(ids), ...
                "Runtime app Id values must be globally unique.");
        end
    end
end
