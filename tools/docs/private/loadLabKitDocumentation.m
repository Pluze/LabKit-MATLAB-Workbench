function model = loadLabKitDocumentation(repoRoot, sourceRoot)
%LOADLABKITDOCUMENTATION Validate narrative pages and discover public APIs.

    configFile = fullfile(sourceRoot, "site.json");
    if ~isfile(configFile)
        error("LabKit:Docs:MissingConfig", ...
            "Documentation source requires docs/site.json.");
    end
    try
        config = jsondecode(fileread(configFile));
    catch ME
        error("LabKit:Docs:InvalidConfig", ...
            "Could not decode docs/site.json: %s", ME.message);
    end
    requireFields(config, ["schemaVersion", "title", "tagline", ...
        "repositoryUrl", "pages"], "site.json");
    if double(config.schemaVersion) ~= 1
        error("LabKit:Docs:UnsupportedSchema", ...
            "Documentation schemaVersion must be 1.");
    end

    rawPages = normalizeStructArray(config.pages);
    pages = repmat(emptyPage(), numel(rawPages), 1);
    for k = 1:numel(rawPages)
        pages(k) = validatePage(rawPages(k), sourceRoot);
    end
    [appPages, apps] = loadAppCatalog(repoRoot, sourceRoot);
    historyPages = discoverHistoryPages(sourceRoot);
    pages = [pages; appPages; historyPages];
    assertUnique(string({pages.id}), "page id");
    assertUnique(string({pages.source}), "page source");
    assertUnique(string({pages.output}), "page output");
    [~, order] = sortrows([[pages.order].', string({pages.title}).']);
    pages = pages(order);

    libraryApi = discoverLabKitPublicApi(repoRoot);
    appApi = discoverAppPublicApi(repoRoot, sourceRoot);
    api = [libraryApi; appApi];
    assertUnique(string({api.symbol}), "public API symbol");
    [~, apiOrder] = sort(string({api.symbol}));
    api = api(apiOrder);
    model = struct( ...
        "repoRoot", string(repoRoot), ...
        "sourceRoot", string(sourceRoot), ...
        "title", string(config.title), ...
        "tagline", string(config.tagline), ...
        "repositoryUrl", string(config.repositoryUrl), ...
        "pages", pages, ...
        "apps", apps, ...
        "history", historyPages, ...
        "api", api);
end

function page = validatePage(raw, sourceRoot)
    requireFields(raw, ["id", "source", "output", "title", ...
        "kind", "nav", "order", "keywords"], "page");
    page = emptyPage();
    page.id = scalarText(raw.id, "id");
    page.source = normalizedRelativePath(scalarText(raw.source, "source"));
    page.output = normalizedRelativePath(scalarText(raw.output, "output"));
    page.title = scalarText(raw.title, "title");
    page.kind = scalarText(raw.kind, "kind");
    page.nav = stringList(raw.nav);
    page.order = double(raw.order);
    page.keywords = stringList(raw.keywords);
    if isfield(raw, "components")
        page.components = stringList(raw.components);
    end
    page.sourcePath = string(fullfile(sourceRoot, page.source));
    if ~isfile(page.sourcePath)
        error("LabKit:Docs:MissingSource", ...
            "Documentation page source does not exist: %s", page.source);
    end
    if ~endsWith(page.source, ".md") || ~endsWith(page.output, ".html")
        error("LabKit:Docs:InvalidPagePath", ...
            "Page %s must map a Markdown source to an HTML output.", page.id);
    end
    if ~isscalar(page.order) || ~isfinite(page.order)
        error("LabKit:Docs:InvalidPageOrder", ...
            "Page %s order must be a finite scalar.", page.id);
    end
end

function page = emptyPage()
    page = struct("id", "", "source", "", "sourcePath", "", ...
        "output", "", "title", "", "kind", "", ...
        "nav", strings(0, 1), "order", 0, ...
        "keywords", strings(0, 1), "components", strings(0, 1), ...
        "historyId", "", "historyDate", "", "historySequence", NaN, ...
        "changeType", "", ...
        "compatibility", "");
end

function pages = discoverHistoryPages(sourceRoot)
    entries = dir(fullfile(sourceRoot, "history", "records", "**", "*.md"));
    pages = repmat(emptyPage(), numel(entries), 1);
    for k = 1:numel(entries)
        filepath = string(fullfile(entries(k).folder, entries(k).name));
        source = replace(extractAfter(filepath, string(sourceRoot) + filesep), ...
            filesep, "/");
        text = string(fileread(filepath));
        lines = splitlines(text);
        titleLine = find(startsWith(lines, "# "), 1);
        if isempty(titleLine)
            error("LabKit:Docs:InvalidHistory", ...
                "History page has no level-one title: %s", source);
        end
        historySchema = historyScalar(lines, "schema", source);
        if historySchema ~= "2"
            error("LabKit:Docs:UnsupportedHistorySchema", ...
                "History page %s must use schema 2.", source);
        end
        historyId = historyScalar(lines, "id", source);
        historyDate = historyScalar(lines, "date", source);
        historySequence = historySequenceScalar(lines, source);
        changeType = historyScalar(lines, "type", source);
        compatibility = historyScalar(lines, "compatibility", source);
        componentLines = lines(startsWith(lines, "component:") | ...
            startsWith(lines, "introduced:"));
        components = strings(0, 1);
        for iLine = 1:numel(componentLines)
            token = regexp(componentLines(iLine), ...
                '^(?:component|introduced):\s*`([^`]+)`', "tokens", "once");
            if isempty(token)
                error("LabKit:Docs:InvalidHistory", ...
                    "History page has malformed component metadata: %s", source);
            end
            components(end + 1, 1) = string(token{1});
        end
        raw = struct( ...
            "id", "history-" + historyId, ...
            "source", source, ...
            "output", erase(source, ".md") + ".html", ...
            "title", extractAfter(lines(titleLine), "# "), ...
            "kind", "history", ...
            "nav", strings(0, 1), ...
            "order", 1000, ...
            "keywords", [historyId; historyDate; string(historySequence); ...
                changeType; compatibility; components], ...
            "components", unique(components, "stable"));
        page = validatePage(raw, sourceRoot);
        page.historyId = historyId;
        page.historyDate = historyDate;
        page.historySequence = historySequence;
        page.changeType = changeType;
        page.compatibility = compatibility;
        pages(k) = page;
    end
    if isempty(pages)
        return;
    end
    assertUnique(string({pages.historyId}), "history Change ID");
    sequences = [pages.historySequence].';
    assertUnique(string(sequences), "history sequence");
    expected = (1:numel(pages)).';
    if ~isequal(sort(sequences), expected)
        error("LabKit:Docs:InvalidHistorySequence", ...
            "History sequence values must contain every integer from 1 to %d.", ...
            numel(pages));
    end
    [~, chronologicalOrder] = sort(sequences);
    chronologicalDates = string({pages(chronologicalOrder).historyDate}).';
    if ~isequal(chronologicalDates, sort(chronologicalDates))
        error("LabKit:Docs:InvalidHistorySequence", ...
            "History sequence must not move backward across record dates.");
    end
    [~, order] = sort(sequences, "descend");
    pages = pages(order);
end

function value = historySequenceScalar(lines, source)
    text = historyScalar(lines, "sequence", source);
    if isempty(regexp(text, '^[1-9][0-9]*$', 'once'))
        error("LabKit:Docs:InvalidHistorySequence", ...
            "History page %s sequence must be a positive integer.", source);
    end
    value = str2double(text);
end

function value = historyScalar(lines, key, source)
    prefix = key + ":";
    matches = lines(startsWith(lines, prefix));
    if numel(matches) ~= 1
        error("LabKit:Docs:InvalidHistory", ...
            "History page %s must contain one %s metadata field.", source, key);
    end
    value = strtrim(extractAfter(matches, prefix));
    if strlength(value) == 0
        error("LabKit:Docs:InvalidHistory", ...
            "History page %s has an empty %s metadata field.", source, key);
    end
end

function [pages, apps] = loadAppCatalog(repoRoot, sourceRoot)
    catalogPath = fullfile(sourceRoot, "catalogs", "apps.json");
    if ~isfile(catalogPath)
        error("LabKit:Docs:MissingAppCatalog", ...
            "Documentation source requires docs/catalogs/apps.json.");
    end
    try
        catalog = jsondecode(fileread(catalogPath));
    catch ME
        error("LabKit:Docs:InvalidAppCatalog", ...
            "Could not decode app catalog: %s", ME.message);
    end
    requireFields(catalog, ["schemaVersion", "families", "apps"], "app catalog");
    if double(catalog.schemaVersion) ~= 1
        error("LabKit:Docs:UnsupportedAppCatalog", ...
            "App catalog schemaVersion must be 1.");
    end
    families = normalizeStructArray(catalog.families);
    apps = normalizeStructArray(catalog.apps);
    familyIds = string({families.id});
    assertUnique(familyIds, "app family id");
    assertUnique(string({apps.id}), "app id");
    assertUnique(string({apps.command}), "app command");

    pages = repmat(emptyPage(), numel(families) + numel(apps), 1);
    for k = 1:numel(families)
        family = families(k);
        requireFields(family, ["id", "title", "source", "output", "order"], ...
            "app family");
        raw = struct( ...
            "id", "app-family-" + string(family.id), ...
            "source", string(family.source), ...
            "output", string(family.output), ...
            "title", string(family.title), ...
            "kind", "app family", ...
            "nav", ["Apps"; string(family.title)], ...
            "order", 100 + double(family.order), ...
            "keywords", [string(family.id); string(family.title)], ...
            "components", strings(0, 1));
        pages(k) = validatePage(raw, sourceRoot);
    end
    for k = 1:numel(apps)
        app = apps(k);
        requireFields(app, ["id", "title", "command", "family", "folder", ...
            "source", "output", "description", "keywords"], "app");
        familyIndex = find(familyIds == string(app.family), 1);
        if isempty(familyIndex)
            error("LabKit:Docs:UnknownAppFamily", ...
                "App %s references unknown family %s.", app.id, app.family);
        end
        entryFile = fullfile(repoRoot, string(app.folder), string(app.command) + ".m");
        if ~isfile(entryFile)
            error("LabKit:Docs:MissingAppEntrypoint", ...
                "Cataloged app entry point does not exist: %s", entryFile);
        end
        familyTitle = string(families(familyIndex).title);
        raw = struct( ...
            "id", "app-" + string(app.id), ...
            "source", string(app.source), ...
            "output", string(app.output), ...
            "title", string(app.title), ...
            "kind", "app", ...
            "nav", ["Apps"; familyTitle], ...
            "order", 200 + double(families(familyIndex).order), ...
            "keywords", [string(app.keywords(:)); string(app.command); ...
                string(app.description)], ...
            "components", string(app.command));
        pages(numel(families) + k) = validatePage(raw, sourceRoot);
    end
end

function api = discoverLabKitPublicApi(repoRoot)
    root = fullfile(repoRoot, "+labkit");
    entries = dir(fullfile(root, "**", "*.m"));
    api = repmat(emptyApi(), 0, 1);
    for k = 1:numel(entries)
        filepath = string(fullfile(entries(k).folder, entries(k).name));
        if contains(filepath, filesep + "private" + filesep)
            continue;
        end
        item = readApiItem(repoRoot, filepath, "library", "labkit");
        api(end + 1, 1) = item;
    end
    [~, order] = sort(string({api.symbol}));
    api = api(order);
end

function api = discoverAppPublicApi(repoRoot, sourceRoot)
    catalogPath = fullfile(sourceRoot, "catalogs", "api.json");
    if ~isfile(catalogPath)
        error("LabKit:Docs:MissingApiCatalog", ...
            "Documentation source requires docs/catalogs/api.json.");
    end
    try
        catalog = jsondecode(fileread(catalogPath));
    catch ME
        error("LabKit:Docs:InvalidApiCatalog", ...
            "Could not decode app API catalog: %s", ME.message);
    end
    requireFields(catalog, ["schemaVersion", "appApis"], "api catalog");
    if double(catalog.schemaVersion) ~= 1
        error("LabKit:Docs:UnsupportedApiCatalog", ...
            "App API catalog schemaVersion must be 1.");
    end
    entries = normalizeStructArray(catalog.appApis);
    api = repmat(emptyApi(), numel(entries), 1);
    for k = 1:numel(entries)
        requireFields(entries(k), ["source", "app", "family"], ...
            "app API entry");
        source = normalizedRepositoryPath(entries(k).source);
        filepath = string(fullfile(repoRoot, source));
        if ~isfile(filepath)
            error("LabKit:Docs:MissingAppApi", ...
                "Cataloged app API does not exist: %s", source);
        end
        if contains("/" + source + "/", "/private/")
            error("LabKit:Docs:PrivateApiCatalog", ...
                "Private helpers cannot be published as app APIs: %s", source);
        end
        api(k) = readApiItem(repoRoot, filepath, "app", entries(k).app);
        api(k).family = char(scalarText(entries(k).family, "family"));
    end
end

function item = readApiItem(repoRoot, filepath, origin, owner)
    relative = replace(extractAfter(filepath, string(repoRoot) + filesep), ...
        filesep, "/");
    parts = split(relative, "/");
    packageParts = parts(startsWith(parts, "+"));
    packageParts = erase(packageParts, "+");
    functionName = erase(parts(end), ".m");
    symbol = strjoin([packageParts; functionName], ".");

    lines = readlines(filepath, "EmptyLineRule", "read");
    start = find(startsWith(strtrim(lines), "function"), 1);
    if isempty(start)
        error("LabKit:Docs:MissingFunction", ...
            "Public API file has no function declaration: %s", relative);
    end
    finish = start;
    while finish < numel(lines) && endsWith(strip(lines(finish)), "...")
        finish = finish + 1;
    end
    signature = strjoin(strip(lines(start:finish)), newline);
    leadingHelp = leadingCommentBlock(lines, start);
    helpLines = strings(0, 1);
    index = finish + 1;
    while index <= numel(lines)
        line = lines(index);
        trimmed = strtrim(line);
        if ~startsWith(trimmed, "%")
            break;
        end
        text = extractAfter(trimmed, 1);
        if startsWith(text, " ")
            text = extractAfter(text, 1);
        end
        helpLines(end + 1, 1) = text;
        index = index + 1;
    end
    if isempty(helpLines) && ~isempty(leadingHelp)
        helpLines = leadingHelp;
    end
    if isempty(helpLines)
        error("LabKit:Docs:MissingApiContract", ...
            "Public API file has no help contract: %s", relative);
    end
    summary = strip(helpLines(1));
    item = struct( ...
        "symbol", char(symbol), ...
        "signature", char(signature), ...
        "summary", char(summary), ...
        "helpText", char(strjoin(helpLines, newline)), ...
        "source", char(relative), ...
        "origin", char(origin), ...
        "owner", char(owner), ...
        "family", "");
end

function comments = leadingCommentBlock(lines, functionStart)
    comments = strings(0, 1);
    for k = 1:(functionStart - 1)
        trimmed = strtrim(lines(k));
        if startsWith(trimmed, "%")
            text = extractAfter(trimmed, 1);
            if startsWith(text, " ")
                text = extractAfter(text, 1);
            end
            comments(end + 1, 1) = text;
        elseif strlength(trimmed) > 0
            comments = strings(0, 1);
        end
    end
end

function item = emptyApi()
    item = struct("symbol", "", "signature", "", "summary", "", ...
        "helpText", "", "source", "", "origin", "", ...
        "owner", "", "family", "");
end

function value = scalarText(value, field)
    value = string(value);
    if ~isscalar(value) || strlength(value) == 0
        error("LabKit:Docs:InvalidField", ...
            "Documentation field %s must be nonempty scalar text.", field);
    end
end

function values = stringList(value)
    if isempty(value)
        values = strings(0, 1);
    else
        values = string(value(:));
    end
end

function path = normalizedRelativePath(path)
    path = replace(string(path), "\", "/");
    if startsWith(path, "/") || contains(path, "../") || contains(path, "/..")
        error("LabKit:Docs:InvalidPath", ...
            "Documentation paths must stay inside docs/: %s", path);
    end
end

function path = normalizedRepositoryPath(path)
    path = replace(string(path), "\", "/");
    if startsWith(path, "/") || contains(path, "../") || contains(path, "/..")
        error("LabKit:Docs:InvalidRepositoryPath", ...
            "API catalog paths must stay inside the repository: %s", path);
    end
end

function requireFields(value, fields, context)
    missing = fields(~isfield(value, fields));
    if ~isempty(missing)
        error("LabKit:Docs:MissingField", ...
            "%s is missing required field %s.", context, missing(1));
    end
end

function assertUnique(values, label)
    if numel(unique(values)) ~= numel(values)
        error("LabKit:Docs:DuplicateValue", ...
            "Documentation contains a duplicate %s.", label);
    end
end

function values = normalizeStructArray(values)
    if isempty(values)
        values = struct([]);
    elseif iscell(values)
        fields = strings(0, 1);
        for k = 1:numel(values)
            fields = union(fields, string(fieldnames(values{k})), "stable");
        end
        template = cell2struct(cell(numel(fields), 1), cellstr(fields), 1);
        normalized = repmat(template, numel(values), 1);
        for k = 1:numel(values)
            itemFields = string(fieldnames(values{k}));
            for iField = 1:numel(itemFields)
                field = itemFields(iField);
                normalized(k).(field) = values{k}.(field);
            end
        end
        values = normalized;
    end
end
