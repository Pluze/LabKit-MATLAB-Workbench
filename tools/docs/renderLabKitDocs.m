function result = renderLabKitDocs(sourceRoot, outputRoot)
%RENDERLABKITDOCS Build the tracked LabKit static documentation site.
% Expected caller: buildtool docs, tests, and release preparation.
% Inputs:
%   sourceRoot - documentation source folder containing site.json.
%   outputRoot - destination for generated HTML and static assets.
% Output:
%   result - struct with pageCount, apiCount, fileCount, and paths.
% Side effects: synchronizes outputRoot with deterministic generated output.

    repoRoot = fileparts(fileparts(fileparts(mfilename("fullpath"))));
    if nargin < 1 || strlength(string(sourceRoot)) == 0
        sourceRoot = fullfile(repoRoot, "docs");
    end
    if nargin < 2 || strlength(string(outputRoot)) == 0
        outputRoot = fullfile(repoRoot, "site");
    end

    model = loadLabKitDocumentation(repoRoot, sourceRoot);
    stagingRoot = string(tempname);
    cleanup = onCleanup(@() removeDocFolder(stagingRoot));
    mkdir(stagingRoot);

    renderedPages = renderNarrativePages(model, stagingRoot);
    apiPages = renderPublicApiPages(model, stagingRoot);
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

    syncLabKitDocTree(stagingRoot, outputRoot);
    clear cleanup

    files = dir(fullfile(outputRoot, "**", "*"));
    result = struct( ...
        "pageCount", numel(model.pages), ...
        "apiCount", numel(model.api), ...
        "fileCount", sum(~[files.isdir]), ...
        "sourceRoot", string(sourceRoot), ...
        "outputRoot", string(outputRoot));
end

function output = renderNarrativePages(model, stagingRoot)
    entries = repmat(emptySearchEntry(), 0, 1);
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
        [historyBody, historyText] = renderLabKitHistoryLinks(model, page);
        body = body + historyBody;
        plainText = plainText + " " + historyText;
        html = renderLabKitPage(model, page.title, page.output, ...
            page.kind, body);
        writeDocText(fullfile(stagingRoot, page.output), html);
        entries(end + 1, 1) = searchEntry(page.title, page.output, ...
            page.kind, strjoin(page.keywords, " ") + " " + plainText);
    end
    output = struct("searchEntries", entries);
end

function output = renderPublicApiPages(model, stagingRoot)
    entries = repmat(emptySearchEntry(), 0, 1);
    for k = 1:numel(model.api)
        item = model.api(k);
        outputPath = "reference/api/" + replace(item.symbol, ".", "/") + ".html";
        body = renderLabKitApiBody(model, item, outputPath);
        html = renderLabKitPage(model, item.symbol, outputPath, ...
            "reference", body);
        writeDocText(fullfile(stagingRoot, outputPath), html);
        entries(end + 1, 1) = searchEntry(item.symbol, outputPath, ...
            "reference", item.summary + " " + item.helpText);
    end
    output = struct("searchEntries", entries);
end

function entry = searchEntry(title, url, kind, text)
    entry = struct("title", char(title), "url", char(url), ...
        "kind", char(kind), "text", char(normalizeSearchText(text)));
end

function entry = emptySearchEntry()
    entry = struct("title", "", "url", "", "kind", "", "text", "");
end

function text = normalizeSearchText(text)
    text = regexprep(string(text), '\s+', ' ');
    text = strip(text);
end

function removeDocFolder(folder)
    if isfolder(folder)
        rmdir(folder, "s");
    end
end
