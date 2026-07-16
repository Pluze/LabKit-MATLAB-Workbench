classdef ProjectDocumentationGuardrailTest < matlab.unittest.TestCase
    %PROJECTDOCUMENTATIONGUARDRAILTEST Documentation ownership and contract checks.

    methods (Test, TestTags = {'Integration', 'Style'})
        function humanDocsDoNotContainAgentOnlyWorkflowMandates(testCase)
            root = setupLabKitTestPath();
            files = collectHumanDocFiles(root);
            forbidden = [ ...
                "Codex", ...
                "agent-only", ...
                "git handoff", ...
                "dedicated development branch", ...
                "force-push", ...
                "Conventional Commits", ...
                "commit hash", ...
                "branch deletion", ...
                "current turn", ...
                "final response"];

            leaks = strings(1, 0);
            for k = 1:numel(files)
                content = lower(string(fileread(files(k))));
                for iWord = 1:numel(forbidden)
                    if contains(content, lower(forbidden(iWord)))
                        leaks(end+1) = relativePath(root, files(k)) + ...
                            " -> " + forbidden(iWord);
                    end
                end
            end

            testCase.verifyTrue(isempty(leaks), ...
                ['Human docs should not contain agent-only workflow mandates: ' ...
                strjoin(cellstr(leaks), ', ')]);
        end

        function testingDocOwnsBuildTaskCommandMatrix(testCase)
            root = setupLabKitTestPath();
            canonical = fullfile(root, "docs", "development", "testing.md");
            canonicalTasks = extractBuildtoolTaskNames(fileread(canonical));
            testCase.verifyGreaterThanOrEqual(numel(canonicalTasks), 5, ...
                'docs/development/testing.md should remain the canonical build-task matrix.');

            files = collectGuidanceFilesExceptTesting(root);
            duplicates = strings(1, 0);
            for k = 1:numel(files)
                tasks = extractBuildtoolTaskNames(fileread(files(k)));
                if numel(tasks) > 1
                    duplicates(end+1) = relativePath(root, files(k)) + ...
                        " -> " + strjoin(tasks, " ");
                end
            end

            testCase.verifyTrue(isempty(duplicates), ...
                ['Only docs/development/testing.md should maintain a build-task command matrix: ' ...
                strjoin(cellstr(duplicates), ', ')]);
        end

        function releaseDocsPinLauncherAssetToTagBlob(testCase)
            root = setupLabKitTestPath();
            releaseDoc = string(fileread(fullfile(root, "docs", ...
                "development", "release.md")));
            agentDoc = string(fileread(fullfile(root, "AGENTS.md")));
            gitAttributes = string(fileread(fullfile(root, ".gitattributes")));

            requiredReleasePhrases = [ ...
                "git show vX.Y.Z:labkit_launcher.m", ...
                "shasum -a 256", ...
                "wc -c", ...
                "gh release view vX.Y.Z --json assets", ...
                "Do not move" ...
            ];
            for k = 1:numel(requiredReleasePhrases)
                testCase.verifyTrue(contains(releaseDoc, requiredReleasePhrases(k)), ...
                    "docs/development/release.md should preserve launcher asset reproducibility rule: " + ...
                    requiredReleasePhrases(k));
            end

            requiredAgentPhrases = [ ...
                "Release assets must be reproducible from the tag", ...
                "working-tree copy", ...
                "uploaded asset size and SHA-256 digest match" ...
            ];
            for k = 1:numel(requiredAgentPhrases)
                testCase.verifyTrue(contains(agentDoc, requiredAgentPhrases(k)), ...
                    "AGENTS.md should preserve release asset execution rule: " + ...
                    requiredAgentPhrases(k));
            end

            requiredAttributes = [ ...
                "* text=auto eol=lf", ...
                "*.m text eol=lf", ...
                "*.md text eol=lf" ...
            ];
            for k = 1:numel(requiredAttributes)
                testCase.verifyTrue(contains(gitAttributes, requiredAttributes(k)), ...
                    ".gitattributes should pin text line endings: " + ...
                    requiredAttributes(k));
            end
        end

        function publicLibraryFunctionsDocumentAppFacingContracts(testCase)
            root = setupLabKitTestPath();
            publicFiles = collectPublicLibraryFiles(root);
            missing = strings(1, 0);
            for k = 1:numel(publicFiles)
                if ~hasFunctionContractComment(publicFiles(k))
                    missing(end+1) = string(relativePath(root, publicFiles(k)));
                end
            end

            testCase.verifyTrue(isempty(missing), ...
                ['Public +labkit functions need app-facing contract comments immediately ' ...
                'after the function declaration: ' strjoin(cellstr(missing), ', ')]);
        end

        function publicApiIndexCoversPublicLibrarySurface(testCase)
            root = setupLabKitTestPath();
            referenceRoot = fullfile(root, "site", "reference");
            indexText = string(fileread(fullfile(referenceRoot, "index.html")));
            publicFiles = collectPublicLibraryFiles(root);
            missing = strings(1, 0);
            for k = 1:numel(publicFiles)
                symbol = publicApiSymbol(root, publicFiles(k));
                relativeOutput = "api/" + replace(symbol, ".", "/") + ".html";
                outputFile = fullfile(referenceRoot, ...
                    replace(relativeOutput, "/", filesep));
                expectedLink = "href=""" + relativeOutput + """";
                if ~isfile(outputFile) || ~contains(indexText, expectedLink)
                    missing(end+1) = symbol;
                end
            end

            testCase.verifyTrue(isempty(missing), ...
                ['Generated API reference should link every supported public ' ...
                '+labkit function to its own source-bound page: ' ...
                strjoin(cellstr(missing), ', ')]);
        end

        function documentationSourcesUseReaderOrientedHierarchy(testCase)
            root = setupLabKitTestPath();
            docsRoot = fullfile(root, "docs");
            retired = ["api", "guides", "tools"];
            for k = 1:numel(retired)
                testCase.verifyFalse(isfolder(fullfile(docsRoot, retired(k))), ...
                    "Retired mixed-purpose documentation folder returned: " + retired(k));
            end

            mFiles = dir(fullfile(docsRoot, "**", "*.m"));
            testCase.verifyEmpty(mFiles, ...
                "docs/ contains structured documentation sources, not executable tools.");
            testCase.verifyTrue(isfile(fullfile(docsRoot, "framework", "README.md")));
            testCase.verifyTrue(isfile(fullfile(docsRoot, "libraries", "README.md")));
            testCase.verifyTrue(isfile(fullfile(docsRoot, "history", "README.md")));

            catalog = jsondecode(fileread(fullfile(docsRoot, "catalogs", "apps.json")));
            apps = normalizeDocStructArray(catalog.apps);
            for k = 1:numel(apps)
                expected = "apps/" + string(apps(k).family) + "/" + ...
                    string(apps(k).id) + "/README.md";
                testCase.verifyEqual(string(apps(k).source), expected, ...
                    "Each app should own one immediately recognizable documentation directory.");
            end
        end

        function generatedDocumentationMatchesTrackedSources(testCase)
            root = setupLabKitTestPath();
            toolFolder = fullfile(root, "tools", "docs");
            addpath(toolFolder);
            cleanup = onCleanup(@() rmpath(toolFolder));

            result = checkLabKitDocs(fullfile(root, "docs"), ...
                fullfile(root, "site"));

            testCase.verifyGreaterThan(result.pageCount, 15, ...
                "Documentation site should contain the narrative hierarchy.");
            testCase.verifyGreaterThan(result.apiCount, 100, ...
                "Documentation site should include library and app-owned public APIs.");
            testCase.verifyGreaterThan(result.comparedFileCount, result.apiCount, ...
                "Generated tree comparison should include pages and static assets.");
            clear cleanup
        end

        function generatedSearchIncludesPublicApisAndExcludesPrivateHelpers(testCase)
            root = setupLabKitTestPath();
            searchFile = fullfile(root, "site", "assets", "search-index.json");
            testCase.assertTrue(isfile(searchFile), ...
                "Tracked site should contain a generated search index.");
            entries = jsondecode(fileread(searchFile));
            titles = string({entries.title});

            testCase.verifyTrue(any(titles == "labkit.thermal.rawToTemperatureC"), ...
                "Search should index reusable scientific APIs.");
            testCase.verifyTrue(any(titles == "cic.analysisRun.computeCIC"), ...
                "Search should index explicitly cataloged app scientific APIs.");
            testCase.verifyFalse(any(contains(titles, ".private.")), ...
                "Search should not publish private implementation helpers.");
        end

        function generatedSearchWorksWhenSiteIsOpenedFromDisk(testCase)
            root = setupLabKitTestPath();
            assetFolder = fullfile(root, "site", "assets");
            indexJson = string(fileread(fullfile(assetFolder, "search-index.json")));
            indexScript = string(fileread(fullfile(assetFolder, "search-index.js")));
            appScript = string(fileread(fullfile(assetFolder, "app.js")));
            homePage = string(fileread(fullfile(root, "site", "index.html")));

            testCase.verifyEqual(indexScript, ...
                "window.LABKIT_SEARCH_INDEX = " + indexJson + ";", ...
                "The file-safe search script should carry the generated JSON index.");
            testCase.verifyTrue(contains(appScript, "window.LABKIT_SEARCH_INDEX"));
            testCase.verifyFalse(contains(appScript, "fetch(") || ...
                contains(appScript, "XMLHttpRequest"), ...
                ["Search must not fetch a sibling file because browsers block " ...
                "that request when generated HTML is opened through file://."]);
            indexPosition = strfind(homePage, "assets/search-index.js");
            appPosition = strfind(homePage, "assets/app.js");
            testCase.verifyTrue(isscalar(indexPosition) && isscalar(appPosition) && ...
                indexPosition < appPosition, ...
                "Every page should load the search index before the search behavior.");
        end

        function generatedMarkdownLinksAreNavigable(testCase)
            root = setupLabKitTestPath();
            homePage = string(fileread(fullfile(root, "site", "index.html")));

            testCase.verifyTrue(contains(homePage, ...
                '<a href="getting-started/index.html">Getting started</a>'), ...
                "Links inside Markdown tables should become site-relative anchors.");
            testCase.verifyTrue(contains(homePage, ...
                '<a href="history/index.html">Project history</a>'), ...
                "Links inside Markdown lists should become site-relative anchors.");
            testCase.verifyFalse(contains(homePage, ...
                "[Getting started](getting-started/README.md)"), ...
                "Generated HTML must not expose unparsed Markdown links.");
        end

        function generatedSiteContainsNoLocalMarkdownLinks(testCase)
            root = setupLabKitTestPath();
            pages = dir(fullfile(root, "site", "**", "*.html"));
            offenders = strings(0, 1);
            for k = 1:numel(pages)
                text = string(fileread(fullfile(pages(k).folder, pages(k).name)));
                if ~isempty(regexp(text, ...
                        'href="(?!https?://|mailto:)[^"]+[.]md(?:#[^"]*)?"', ...
                        'once'))
                    offenders(end + 1, 1) = string(fullfile( ...
                        pages(k).folder, pages(k).name));
                end
            end
            testCase.verifyEmpty(offenders, ...
                "Generated pages must resolve every local Markdown link to HTML.");
        end

        function appApiCatalogIsExplicitAndContainsNoPrivatePaths(testCase)
            root = setupLabKitTestPath();
            catalog = jsondecode(fileread(fullfile(root, "docs", ...
                "catalogs", "api.json")));
            entries = normalizeDocStructArray(catalog.appApis);
            testCase.assertGreaterThan(numel(entries), 20, ...
                "App API catalog should identify core GUI-free workflows.");
            for k = 1:numel(entries)
                source = string(entries(k).source);
                testCase.verifyFalse(contains("/" + source + "/", "/private/"), ...
                    "Private helpers must not enter detailed API documentation.");
                testCase.verifyTrue(isfile(fullfile(root, source)), ...
                    "Cataloged app API should exist: " + source);
            end
        end

        function privateHelpersDocumentImplementationContracts(testCase)
            root = setupLabKitTestPath();
            actual = collectPrivateHelpersMissingContracts(root);
            testCase.verifyTrue(isempty(actual), ...
                ['private helpers need implementation contracts: ' ...
                strjoin(cellstr(actual), ', ')]);
        end

        function appOwnedPackageHelpersDocumentImplementationContracts(testCase)
            root = setupLabKitTestPath();
            files = collectAppOwnedPackageFiles(root);
            testCase.assertFalse(isempty(files), ...
                'App-owned package contract guardrail should scan package helper files.');

            missing = strings(1, 0);
            for k = 1:numel(files)
                if ~hasTopFileContract(files(k))
                    missing(end+1) = string(relativePath(root, files(k)));
                end
            end

            testCase.verifyTrue(isempty(missing), ...
                ['App-owned package helpers need top-of-file implementation contracts: ' ...
                strjoin(cellstr(missing), ', ')]);
        end
    end
end

function values = normalizeDocStructArray(values)
    if isempty(values)
        values = struct([]);
    elseif iscell(values)
        values = [values{:}];
    end
end

function files = collectHumanDocFiles(root)
    files = string(fullfile(root, "README.md"));
    entries = dir(fullfile(root, "docs", "**", "*.md"));
    for k = 1:numel(entries)
        filepath = string(fullfile(entries(k).folder, entries(k).name));
        if ~isHistoryDocument(filepath)
            files(end+1) = filepath;
        end
    end
end

function files = collectGuidanceFilesExceptTesting(root)
    files = [ ...
        string(fullfile(root, "README.md")), ...
        string(fullfile(root, "AGENTS.md")), ...
        string(fullfile(root, "apps", "AGENTS.md")), ...
        string(fullfile(root, "tests", "AGENTS.md")), ...
        string(fullfile(root, "+labkit", "AGENTS.md"))];

    docEntries = dir(fullfile(root, "docs", "**", "*.md"));
    for k = 1:numel(docEntries)
        filepath = string(fullfile(docEntries(k).folder, docEntries(k).name));
        if endsWith(filepath, fullfile("docs", "development", "testing.md")) || ...
                isHistoryDocument(filepath)
            continue;
        end
        files(end+1) = filepath;
    end

    skillEntries = dir(fullfile(root, ".agents", "skills", "*", "SKILL.md"));
    for k = 1:numel(skillEntries)
        files(end+1) = string(fullfile(skillEntries(k).folder, skillEntries(k).name));
    end
end

function tf = isHistoryDocument(filepath)
    tf = contains(string(filepath), filesep + "history" + filesep);
end

function tasks = extractBuildtoolTaskNames(content)
    tokens = regexp(char(content), ...
        'buildtool[ \t]+([A-Za-z][A-Za-z0-9_]*(?:[ \t]+[A-Za-z][A-Za-z0-9_]*)*)', ...
        'tokens');
    tasks = strings(1, 0);
    for k = 1:numel(tokens)
        tasks = [tasks, split(string(tokens{k}{1})).'];
    end
    tasks = unique(tasks(strlength(tasks) > 0), 'stable');
end

function files = collectPublicLibraryFiles(root)
    allFiles = dir(fullfile(root, '+labkit', '**', '*.m'));
    files = strings(1, 0);
    for k = 1:numel(allFiles)
        filepath = fullfile(allFiles(k).folder, allFiles(k).name);
        if ~contains(filepath, [filesep 'private' filesep])
            files(end+1) = string(filepath);
        end
    end
end

function symbol = publicApiSymbol(root, filepath)
    rel = string(relativePath(root, filepath));
    parts = split(rel, "/");
    packageParts = erase(parts(startsWith(parts, "+")), "+");
    functionName = erase(parts(end), ".m");
    symbol = strjoin([packageParts; functionName], ".");
end

function tf = hasFunctionContractComment(filepath)
    lines = leadingFunctionBlock(filepath);
    tf = numel(lines) >= 2 && startsWith(strtrim(lines(2)), "%");
end

function actual = collectPrivateHelpersMissingContracts(root)
    privateDirs = [ ...
        collectPrivateDirs(fullfile(root, '+labkit')), ...
        collectPrivateDirs(fullfile(root, 'apps'))];
    actual = strings(1, 0);
    for k = 1:numel(privateDirs)
        folder = privateDirs(k);
        if ~isTrackedPrivateScope(root, folder)
            continue;
        end
        files = dir(fullfile(char(folder), '*.m'));
        for f = 1:numel(files)
            filepath = fullfile(files(f).folder, files(f).name);
            if ~hasTopFileContract(filepath)
                actual(end+1) = string(relativePath(root, filepath));
            end
        end
    end
    actual = unique(actual);
end

function files = collectAppOwnedPackageFiles(root)
    entries = dir(fullfile(root, 'apps', '**', '+*', '**', '*.m'));
    files = strings(1, 0);
    for k = 1:numel(entries)
        filepath = string(fullfile(entries(k).folder, entries(k).name));
        if contains(filepath, [filesep 'private' filesep])
            continue;
        end
        files(end+1) = filepath;
    end
    files = unique(files);
end

function folders = collectPrivateDirs(folder)
    folders = strings(1, 0);
    if ~isfolder(folder)
        return;
    end
    entries = dir(folder);
    [~, order] = sort({entries.name});
    entries = entries(order);
    for k = 1:numel(entries)
        entry = entries(k);
        if ~entry.isdir || any(strcmp(entry.name, {'.', '..'}))
            continue;
        end
        child = fullfile(entry.folder, entry.name);
        if strcmp(entry.name, 'private')
            folders(end+1) = string(child);
        else
            folders = [folders, collectPrivateDirs(child)];
        end
    end
end

function tf = isTrackedPrivateScope(root, folder)
    rel = string(relativePath(root, folder));
    tf = startsWith(rel, "+labkit/") || startsWith(rel, "apps/");
end

function tf = hasTopFileContract(filepath)
    first = firstNonEmptyLine(filepath);
    tf = ~isempty(first) && startsWith(first, "%");
end

function first = firstNonEmptyLine(filepath)
    first = strings(0);
    fid = fopen(filepath, "r");
    if fid < 0
        return;
    end
    cleaner = onCleanup(@() fclose(fid));
    while ~feof(fid)
        line = strtrim(string(fgetl(fid)));
        if strlength(line) > 0
            first = line;
            return;
        end
    end
end

function lines = leadingFunctionBlock(filepath)
    lines = strings(1, 0);
    fid = fopen(filepath, "r");
    if fid < 0
        return;
    end
    cleaner = onCleanup(@() fclose(fid));
    foundFunction = false;
    while ~feof(fid)
        line = string(fgetl(fid));
        trimmed = strtrim(line);
        if ~foundFunction
            if startsWith(trimmed, "function ")
                lines(end+1) = trimmed;
                foundFunction = true;
            end
            continue;
        end
        if strlength(trimmed) == 0
            continue;
        end
        lines(end+1) = trimmed;
        return;
    end
end

function rel = relativePath(root, filepath)
    rel = char(filepath);
    prefix = [root filesep];
    if startsWith(rel, prefix)
        rel = rel(numel(prefix)+1:end);
    end
    rel = strrep(rel, filesep, '/');
end
