classdef AppIsolatedPathCoverageGuardrailTest < matlab.unittest.TestCase
    %APPISOLATEDPATHCOVERAGEGUARDRAILTEST Require one owned contract per App.

    methods (Test, TestTags = {'Integration', 'Style'})
        function everyPublicAppHasAnOwnedUnitAppContract(testCase)
            root = labkitRepoRoot();
            apps = publicAppFolders(root);
            missing = apps(~arrayfun(@(appFolder) isfolder(fullfile( ...
                root, "tests", "cases", "unit", "apps", appFolder, ...
                "appContract")), apps));
            testCase.verifyEmpty(missing, ...
                "Public Apps missing owned unit appContract tests: " + ...
                strjoin(missing, ", "));
        end

        function everyPublicAppHasAnOwnedIsolatedPathContract(testCase)
            root = labkitRepoRoot();
            apps = publicAppFolders(root);
            missing = strings(1, 0);
            for k = 1:numel(apps)
                relative = apps(k);
                pieces = split(relative, "/");
                contractFolder = fullfile(root, "tests", "cases", "contract", ...
                    "apps", pieces(1), pieces(2), "isolatedPath");
                if ~isfolder(contractFolder) || isempty(dir( ...
                        fullfile(contractFolder, "*Test.m")))
                    missing(end + 1) = relative;
                end
            end
            testCase.verifyEmpty(missing, ...
                "Public Apps missing owned isolated-path contracts: " + ...
                strjoin(missing, ", "));
        end

        function everyPublicAppHasAnOwnedGuiSmokeProof(testCase)
            root = labkitRepoRoot();
            apps = publicAppFolders(root);
            missing = apps(~arrayfun(@(appFolder) isfolder(fullfile( ...
                root, "tests", "cases", "gui", "apps", appFolder, ...
                "smoke")), apps));
            testCase.verifyEmpty(missing, ...
                "Public Apps missing owned GUI smoke tests: " + ...
                strjoin(missing, ", "));
        end

        function appTestScopesMatchOwnedSourceCapabilities(testCase)
            root = labkitRepoRoot();
            invalid = invalidAppTestScopes(root);
            testCase.verifyEmpty(invalid, ...
                ["App test scopes must be appContract, workbench, smoke, or " + ...
                "a concrete source capability: " + strjoin(invalid, ", ")]);
        end
    end
end

function invalid = invalidAppTestScopes(root)
    invalid = strings(1, 0);
    for kind = ["unit", "gui"]
        entries = dir(fullfile(root, "tests", "cases", kind, "apps", ...
            "**", "*Test.m"));
        for k = 1:numel(entries)
            relative = replace(string(entries(k).folder), ...
                string(fullfile(root, "tests", "cases", kind, "apps")) + filesep, "");
            parts = split(relative, filesep);
            if numel(parts) < 3
                invalid(end + 1) = kind + "/" + relative;
                continue;
            end
            family = parts(1);
            slug = parts(2);
            scope = parts(3);
            if isStableAppTestScope(scope) || ...
                    appOwnsSourceCapability(root, family, slug, scope)
                continue;
            end
            invalid(end + 1) = kind + "/" + relative;
        end
    end
end

function tf = isStableAppTestScope(scope)
    tf = ismember(string(scope), ["appContract", "workbench", "smoke"]);
end

function tf = appOwnsSourceCapability(root, family, slug, scope)
    packageFolders = dir(fullfile(root, "apps", family, slug, "+*"));
    packageFolders = packageFolders([packageFolders.isdir]);
    tf = false;
    for k = 1:numel(packageFolders)
        if isfolder(fullfile(packageFolders(k).folder, ...
                packageFolders(k).name, "+" + scope))
            tf = true;
            return;
        end
    end
end

function folders = publicAppFolders(root)
    entries = dir(fullfile(root, "apps", "**", "labkit_*_app.m"));
    folders = string({entries.folder});
    prefix = string(fullfile(root, "apps")) + filesep;
    folders = replace(extractAfter(folders, strlength(prefix)), filesep, "/");
    folders = unique(folders, "stable");
end
