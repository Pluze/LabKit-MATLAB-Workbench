classdef AppIsolatedPathCoverageGuardrailTest < matlab.unittest.TestCase
    %APPISOLATEDPATHCOVERAGEGUARDRAILTEST Require one owned contract per App.

    methods (Test, TestTags = {'Integration', 'Style'})
        function everyPublicAppHasAnOwnedIsolatedPathContract(testCase)
            root = labkitRepoRoot();
            entries = dir(fullfile(root, "apps", "**", "labkit_*_app.m"));
            testCase.assertNotEmpty(entries);
            missing = strings(1, 0);
            for k = 1:numel(entries)
                appRoot = string(entries(k).folder);
                relative = extractAfter(appRoot, ...
                    strlength(string(fullfile(root, "apps"))) + 1);
                pieces = split(replace(relative, filesep, "/"), "/");
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
