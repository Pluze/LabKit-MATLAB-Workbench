function result = renderLabKitDocs(sourceRoot, outputRoot)
%RENDERLABKITDOCS Build the tracked LabKit static documentation site.
% Expected caller: buildtool docs, tests, and release preparation.
% Inputs:
%   sourceRoot - documentation source folder containing Markdown pages.
%   outputRoot - destination for generated HTML and static assets.
% Output:
%   result - struct with pageCount, apiCount, fileCount, and paths.
% Side effects: synchronizes outputRoot with deterministic generated output
%   and reports stage plus completed/total progress to the console.

    repoRoot = fileparts(fileparts(fileparts(mfilename("fullpath"))));
    if nargin < 1 || strlength(string(sourceRoot)) == 0
        sourceRoot = fullfile(repoRoot, "docs");
    end
    if nargin < 2 || strlength(string(outputRoot)) == 0
        outputRoot = fullfile(repoRoot, "site");
    end
    sourceRoot = absoluteDocFolder(sourceRoot, false);
    outputRoot = absoluteDocFolder(outputRoot, true);

    reportDocProgress("load sources", 0, 0);
    model = loadLabKitDocumentation(repoRoot, sourceRoot);
    stagingRoot = string(tempname);
    cleanup = onCleanup(@() removeDocFolder(stagingRoot));
    mkdir(stagingRoot);

    renderedPages = renderNarrativePages(model, stagingRoot);
    apiPages = renderPublicApiPages(model, stagingRoot);
    reportDocProgress("write assets", 0, 0);
    writeDocText(fullfile(stagingRoot, "assets", "style.css"), ...
        labKitDocumentationStyle());
    writeDocText(fullfile(stagingRoot, "assets", "app.js"), ...
        labKitDocumentationScript());
    searchEntries = [renderedPages.searchEntries; apiPages.searchEntries];
    searchJson = string(jsonencode(searchEntries));
    writeDocText(fullfile(stagingRoot, "assets", "search-index.json"), searchJson);
    writeDocText(fullfile(stagingRoot, "assets", "search-index.js"), ...
        "window.LABKIT_SEARCH_INDEX = " + searchJson + ";");
    writeDocText(fullfile(stagingRoot, ".nojekyll"), "");

    reportDocProgress("synchronize output", 0, 0);
    syncLabKitDocTree(stagingRoot, outputRoot);
    clear cleanup

    files = dir(fullfile(outputRoot, "**", "*"));
    result = struct( ...
        "pageCount", numel(model.pages), ...
        "apiCount", numel(model.api), ...
        "fileCount", sum(~[files.isdir]), ...
        "sourceRoot", string(sourceRoot), ...
        "outputRoot", string(outputRoot));
    reportDocProgress("complete", result.fileCount, result.fileCount);
end

function folder = absoluteDocFolder(folder, createIfMissing)
    folder = string(folder);
    if createIfMissing && ~isfolder(folder)
        mkdir(folder);
    end
    [status, attributes] = fileattrib(folder);
    if ~status || ~attributes.directory
        error("LabKit:Docs:InvalidFolder", ...
            "Documentation folder does not exist: %s", folder);
    end
    folder = string(attributes.Name);
end

function output = renderNarrativePages(model, stagingRoot)
    entries = repmat(emptySearchEntry(), numel(model.pages), 1);
    total = numel(model.pages);
    reportDocProgress("narrative pages", 0, total);
    for k = 1:numel(model.pages)
        page = model.pages(k);
        [body, plainText] = renderLabKitMarkdown(model, page);
        if page.id == "api"
            [apiIndexBody, apiIndexText] = renderLabKitApiIndex(model, page.output);
            body = body + apiIndexBody;
            plainText = plainText + " " + apiIndexText;
        else
            [apiLinksBody, apiLinksText] = renderLabKitPageApiLinks(model, page);
            body = body + apiLinksBody;
            plainText = plainText + " " + apiLinksText;
        end
        [historyBody, ~] = renderLabKitHistoryLinks(model, page);
        body = body + historyBody;
        body = body + renderLabKitHistorySequenceNavigation(model, page);
        html = renderLabKitPage(model, page.title, page.output, ...
            page.kind, body);
        writeDocText(fullfile(stagingRoot, page.output), html);
        entries(k, 1) = searchEntry(page.title, page.output, ...
            page.kind, page.keywords, plainText);
        if mod(k, 25) == 0 || k == total
            reportDocProgress("narrative pages", k, total);
        end
    end
    output = struct("searchEntries", entries);
end

function output = renderPublicApiPages(model, stagingRoot)
    entries = repmat(emptySearchEntry(), numel(model.api), 1);
    total = numel(model.api);
    reportDocProgress("public API pages", 0, total);
    for k = 1:numel(model.api)
        item = model.api(k);
        outputPath = "reference/api/" + replace(item.symbol, ".", "/") + ".html";
        body = renderLabKitApiBody(model, item, outputPath);
        html = renderLabKitPage(model, item.symbol, outputPath, ...
            "reference", body);
        writeDocText(fullfile(stagingRoot, outputPath), html);
        entries(k, 1) = searchEntry(item.symbol, outputPath, ...
            "reference", item.symbol, item.summary + " " + item.helpText);
        if mod(k, 25) == 0 || k == total
            reportDocProgress("public API pages", k, total);
        end
    end
    output = struct("searchEntries", entries);
end

function entry = searchEntry(title, url, kind, keywords, text)
    entry = struct("title", char(title), "url", char(url), ...
        "kind", char(kind), "section", char(searchSection(url, kind)), ...
        "keywords", char(normalizeSearchText(keywords)), ...
        "text", char(normalizeSearchText(text)));
end

function entry = emptySearchEntry()
    entry = struct("title", "", "url", "", "kind", "", ...
        "section", "", "keywords", "", "text", "");
end

function text = normalizeSearchText(text)
    if ischar(text)
        text = string(cellstr(text));
    else
        text = string(text);
    end
    text = strjoin(text(:).', " ");
    text = regexprep(string(text), '\s+', ' ');
    text = strip(text);
end

function section = searchSection(url, kind)
    url = string(url);
    kind = string(kind);
    if kind == "history" || startsWith(url, "history/")
        section = "history";
    elseif kind == "reference" || startsWith(url, "reference/")
        section = "reference";
    elseif startsWith(url, "apps/")
        section = "apps";
    elseif startsWith(url, "framework/")
        section = "framework";
    elseif startsWith(url, "libraries/")
        section = "libraries";
    elseif startsWith(url, "development/")
        section = "development";
    elseif startsWith(url, "getting-started/")
        section = "getting-started";
    else
        section = "general";
    end
end

function removeDocFolder(folder)
    if isfolder(folder)
        rmdir(folder, "s");
    end
end

function reportDocProgress(stage, completed, total)
    if total > 0
        fprintf("DOCS [%d/%d] %s\n", completed, total, stage);
    else
        fprintf("DOCS [stage] %s\n", stage);
    end
end
