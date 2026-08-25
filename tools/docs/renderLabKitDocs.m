function result = renderLabKitDocs(sourceRoot, outputRoot)
%RENDERLABKITDOCS Build the tracked LabKit static documentation site.
% Expected caller: buildtool docs, tests, and release preparation.
% Inputs:
%   sourceRoot - documentation source folder containing Markdown pages.
%   outputRoot - destination for generated HTML and static assets.
% Output:
%   result - struct with pageCount, apiCount, generatedPageCount, fileCount,
%       and paths.
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
    reportDocProgress("generated indexes", 0, 0);
    generatedPageCount = renderLabKitGeneratedIndexes(model, stagingRoot);
    reportDocProgress("write assets", 0, 0);
    writeDocText(fullfile(stagingRoot, "assets", "style.css"), ...
        readDocumentationAsset(repoRoot, "style.css"));
    writeDocText(fullfile(stagingRoot, "assets", "app.js"), ...
        readDocumentationAsset(repoRoot, "app.js"));
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
        "generatedPageCount", generatedPageCount, ...
        "fileCount", sum(~[files.isdir]), ...
        "sourceRoot", string(sourceRoot), ...
        "outputRoot", string(outputRoot));
    reportDocProgress("complete", result.fileCount, result.fileCount);
end

function content = readDocumentationAsset(repoRoot, name)
    source = fullfile(repoRoot, "tools", "docs", "assets", name);
    if ~isfile(source)
        error("LabKit:Docs:MissingAsset", ...
            "Documentation asset does not exist: %s", source);
    end
    content = string(fileread(source));
end

function folder = absoluteDocFolder(folder, createIfMissing)
    folder = string(folder);
    if createIfMissing && ~isfolder(folder)
        mkdir(folder);
    end
    folder = resolveLabKitDocFolder(folder, ...
        "LabKit:Docs:InvalidFolder", ...
        "Documentation folder does not exist: %s");
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
        if page.id == "changes"
            [overviewBody, overviewText] = ...
                renderLabKitChangesOverview(model, page.output);
            body = body + overviewBody;
            plainText = plainText + " " + overviewText;
        end
        [changeBefore, changeAfter, ~] = ...
            renderLabKitChangeLinks(model, page);
        body = insertAfterTitle(body, changeBefore) + changeAfter;
        html = renderLabKitPage(model, page.title, page.output, ...
            page.type, body);
        writeDocText(fullfile(stagingRoot, page.output), html);
        entries(k, 1) = searchEntry(page.title, page.output, ...
            page.type, page.keywords, page.summary + " " + plainText, ...
            page.audience, page.authority, page.components);
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
        page = struct("source", "", "output", outputPath, ...
            "components", apiComponents(model, item));
        [~, changeAfter, ~] = renderLabKitChangeLinks(model, page);
        body = body + changeAfter;
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

function body = insertAfterTitle(body, addition)
    if strlength(addition) == 0
        return;
    end
    parts = split(string(body), "</h1>");
    if numel(parts) < 2
        error("LabKit:Docs:MissingRenderedTitle", ...
            "Rendered narrative page has no level-one title.");
    end
    body = parts(1) + "</h1>" + addition + ...
        strjoin(parts(2:end), "</h1>");
end

function components = apiComponents(model, item)
    if string(item.origin) == "app"
        id = replace(string(item.owner), "_", "-");
        app = model.apps(string({model.apps.id}) == id);
        components = string(app(1).command);
        return;
    end
    parts = split(string(item.symbol), ".");
    components = strjoin(parts(1:min(2, numel(parts))), ".");
end

function entry = searchEntry(title, url, kind, keywords, text, ...
        audience, authority, components)
    if nargin < 6
        audience = "";
        authority = "current";
        components = strings(0, 1);
    end
    entry = struct("title", char(title), "url", char(url), ...
        "kind", char(kind), "section", char(searchSection(url, kind)), ...
        "audience", char(audience), "authority", char(authority), ...
        "components", char(normalizeSearchText(components)), ...
        "keywords", char(normalizeSearchText(keywords)), ...
        "text", char(normalizeSearchText(text)));
end

function entry = emptySearchEntry()
    entry = struct("title", "", "url", "", "kind", "", ...
        "section", "", "audience", "", "authority", "", ...
        "components", "", "keywords", "", "text", "");
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
    if kind == "reference" || startsWith(url, "reference/")
        section = "reference";
    elseif startsWith(url, "use/")
        section = "use";
    elseif startsWith(url, "develop/")
        section = "develop";
    elseif startsWith(url, "changes/")
        section = "changes";
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
