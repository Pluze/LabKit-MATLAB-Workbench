classdef PublicApiDocumentationGuardrailTest < matlab.unittest.TestCase
    %PUBLICAPIDOCUMENTATIONGUARDRAILTEST Guard API pages and category landing.

    methods (Test, TestTags = {'Integration', 'Style'})
        function publicApiPagesCoverPublicLibrarySurface(testCase)
            root = setupLabKitTestPath();
            referenceRoot = fullfile(root, "site", "reference");
            files = collectPublicLibraryFiles(root);
            missing = strings(1, 0);
            for k = 1:numel(files)
                symbol = publicApiSymbol(root, files(k));
                output = fullfile(referenceRoot, "api", ...
                    replace(symbol, ".", filesep) + ".html");
                if ~isfile(output)
                    missing(end + 1) = symbol;
                end
            end
            testCase.verifyEmpty(missing, ...
                "Every supported public +labkit function needs a source-bound API page.");
        end

        function referenceIndexLinksOnlyToApiCategories(testCase)
            root = setupLabKitTestPath();
            indexText = string(fileread(fullfile(root, "site", ...
                "reference", "index.html")));
            categoryLinks = [ ...
                "../framework/app-sdk-api.html", ...
                "../framework/compatibility/contracts.html", ...
                "../libraries/image/index.html", ...
                "../libraries/thermal/index.html", ...
                "../libraries/dta/index.html", ...
                "../libraries/rhs/index.html", ...
                "../libraries/biosignal/index.html", ...
                "../apps/index.html"];
            for k = 1:numel(categoryLinks)
                testCase.verifyTrue(contains(indexText, ...
                    "href=""" + categoryLinks(k) + """"));
            end
            testCase.verifyFalse(contains(indexText, "href=""api/labkit/"), ...
                "The reference landing page links API categories, not every function.");
        end
    end
end

function files = collectPublicLibraryFiles(root)
    entries = dir(fullfile(root, "+labkit", "**", "*.m"));
    files = strings(1, 0);
    for k = 1:numel(entries)
        filepath = string(fullfile(entries(k).folder, entries(k).name));
        if ~contains(filepath, [filesep "private" filesep]) && ...
                ~contains(filepath, [filesep "@"]) && ...
                ~isHiddenClassFile(filepath)
            files(end + 1) = filepath;
        end
    end
end

function tf = isHiddenClassFile(filepath)
    lines = strip(readlines(filepath, "EmptyLineRule", "skip"));
    lines = lines(~startsWith(lines, "%"));
    tf = ~isempty(lines) && startsWith(lines(1), "classdef") && ...
        contains(lines(1), "Hidden");
end

function symbol = publicApiSymbol(root, filepath)
    parts = split(string(relativePath(root, filepath)), "/");
    packages = erase(parts(startsWith(parts, "+")), "+");
    symbol = strjoin([packages; erase(parts(end), ".m")], ".");
end
