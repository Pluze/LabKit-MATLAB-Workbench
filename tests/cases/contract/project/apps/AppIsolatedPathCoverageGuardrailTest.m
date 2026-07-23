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
    end
end

function folders = publicAppFolders(root)
    entries = dir(fullfile(root, "apps", "**", "labkit_*_app.m"));
    folders = string({entries.folder});
    prefix = string(fullfile(root, "apps")) + filesep;
    folders = replace(extractAfter(folders, strlength(prefix)), filesep, "/");
    folders = unique(folders, "stable");
end
