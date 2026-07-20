classdef DocumentationSearchContractTest < matlab.unittest.TestCase
    %DOCUMENTATIONSEARCHCONTRACTTEST Search keeps pages and history distinct.

    methods (Test, TestTags = {'Integration', 'Style'})
        function generatedIndexSeparatesPageContentFromHistoryLinks(testCase)
            root = setupLabKitTestPath();
            entries = jsondecode(fileread(fullfile(root, "site", "assets", ...
                "search-index.json")));
            titles = string({entries.title});
            eis = entries(titles == "EIS");

            testCase.assertTrue(isscalar(eis));
            testCase.verifyEqual(string(eis.section), "apps");
            testCase.verifyNotEmpty(string(eis.keywords));
            testCase.verifyFalse(contains(lower(string(eis.text)), "gait"), ...
                ["App search text must not inherit component names from its " ...
                "rendered change-history links."]);
        end

        function generatedSearchSupportsSectionFiltersAndWeightedRanking(testCase)
            root = setupLabKitTestPath();
            appScript = string(fileread(fullfile(root, "site", "assets", ...
                "app.js")));
            page = string(fileread(fullfile(root, "site", "index.html")));

            testCase.verifyTrue(contains(page, "doc-search-section"));
            testCase.verifyTrue(contains(page, 'value="history"'));
            testCase.verifyTrue(contains(appScript, "scoreItem"));
            testCase.verifyTrue(contains(appScript, "fieldScore(title, term, 400)"));
            testCase.verifyTrue(contains(appScript, "item.section === section.value"));
            testCase.verifyTrue(contains(appScript, "excerpt(item, terms)"));
        end
    end
end
