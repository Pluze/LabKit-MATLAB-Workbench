function model = loadLabKitDocumentation(repoRoot, sourceRoot)
%LOADLABKITDOCUMENTATION Discover and validate documentation source contracts.

    apps = discoverPublicApps(repoRoot, sourceRoot);
    pages = discoverNarrativePages(sourceRoot, apps);
    historyPages = discoverHistoryPages(sourceRoot);
    pages = [pages; historyPages];
    assertUnique(string({pages.id}), "page id");
    assertUnique(string({pages.source}), "page source");
    assertUnique(string({pages.output}), "page output");
    [~, order] = sortrows([[pages.order].', string({pages.title}).']);
    pages = pages(order);

    libraryApi = discoverLabKitPublicApi(repoRoot);
    appApi = discoverAppPublicApi(repoRoot, apps);
    api = [libraryApi; appApi];
    assertUnique(string({api.symbol}), "public API symbol");
    [~, apiOrder] = sort(string({api.symbol}));
    api = api(apiOrder);
    [siteTitle, repositoryUrl] = repositoryIdentity(repoRoot);
    model = struct( ...
        "repoRoot", string(repoRoot), ...
        "sourceRoot", string(sourceRoot), ...
        "title", siteTitle, ...
        "repositoryUrl", repositoryUrl, ...
        "pages", pages, ...
        "apps", apps, ...
        "history", historyPages, ...
        "api", api);
end

function [title, repositoryUrl] = repositoryIdentity(repoRoot)
    readme = fullfile(repoRoot, "README.md");
    if ~isfile(readme)
        error("LabKit:Docs:MissingRepositoryReadme", ...
            "Documentation discovery requires the repository README.md.");
    end
    text = string(fileread(readme));
    lines = splitlines(text);
    heading = lines(startsWith(lines, "# "));
    if isempty(heading)
        error("LabKit:Docs:MissingRepositoryTitle", ...
            "Repository README.md must contain a level-one title.");
    end
    title = strip(extractAfter(heading(1), "# "));
    token = regexp(char(text), ...
        'https://github[.]com/[^/\s)]+/[^/\s)#]+', "match", "once");
    if isempty(token)
        error("LabKit:Docs:MissingRepositoryUrl", ...
            "Repository README.md must link to its GitHub repository.");
    end
    repositoryUrl = string(token);
end

function pages = discoverNarrativePages(sourceRoot, apps)
    entries = dir(fullfile(sourceRoot, "**", "*.md"));
    sources = strings(numel(entries), 1);
    sourceCount = 0;
    for k = 1:numel(entries)
        if strcmpi(entries(k).name, "AGENTS.md")
            continue;
        end
        filepath = string(fullfile(entries(k).folder, entries(k).name));
        source = replace(extractAfter(filepath, string(sourceRoot) + filesep), ...
            filesep, "/");
        if startsWith(source, "history/records/")
            continue;
        end
        sourceCount = sourceCount + 1;
        sources(sourceCount, 1) = source;
    end
    sources = sort(sources(1:sourceCount));
    pages = repmat(emptyPage(), numel(sources), 1);
    for k = 1:numel(sources)
        source = sources(k);
        filepath = string(fullfile(sourceRoot, source));
        text = string(fileread(filepath));
        title = markdownTitle(text, source);
        [id, output, kind, nav, components] = ...
            narrativeIdentity(source, apps);
        raw = struct( ...
            "id", id, ...
            "source", source, ...
            "output", output, ...
            "title", title, ...
            "kind", kind, ...
            "nav", nav, ...
            "order", double(k), ...
            "keywords", [pathWords(source); title], ...
            "components", components);
        pages(k) = validatePage(raw, sourceRoot);
    end
end

function title = markdownTitle(text, source)
    lines = splitlines(text);
    matches = lines(startsWith(lines, "# "));
    if isempty(matches)
        error("LabKit:Docs:MissingTitle", ...
            "Documentation page has no level-one title: %s", source);
    end
    if numel(matches) > 1
        error("LabKit:Docs:DuplicateTitle", ...
            "Documentation page has multiple level-one titles: %s", source);
    end
    title = strip(extractAfter(matches, "# "));
end

function [id, output, kind, nav, components] = ...
        narrativeIdentity(source, apps)
    source = string(source);
    isReadme = endsWith(source, "/README.md") || source == "README.md";
    stem = erase(source, ".md");
    if isReadme
        folder = erase(source, "/README.md");
        if source == "README.md"
            folder = "";
        end
        output = folder + "/index.html";
        output = strip(output, "/");
        if strlength(output) == 0
            output = "index.html";
        end
    else
        output = stem + ".html";
    end

    id = replace(lower(stem), ["/", "_"], "-");
    id = erase(id, "-readme");
    kind = "guide";
    if isReadme
        kind = "overview";
    end
    nav = strings(0, 1);
    components = strings(0, 1);

    appIndex = find(string({apps.source}) == source, 1);
    familyIndex = find(string({apps.familySource}) == source, 1);
    if ~isempty(appIndex)
        app = apps(appIndex);
        id = "app-" + string(app.id);
        output = string(app.output);
        kind = "app";
        nav = ["Apps"; string(app.familyTitle)];
        components = string(app.command);
    elseif ~isempty(familyIndex)
        app = apps(familyIndex);
        id = "app-family-" + string(app.family);
        kind = "app family";
        nav = ["Apps"; string(app.familyTitle)];
    elseif source == "README.md"
        id = "home";
        kind = "overview";
    elseif source == "getting-started/README.md"
        id = "getting-started";
        kind = "tutorial";
        nav = "Getting Started";
        components = "labkit_launcher";
    elseif source == "apps/README.md"
        id = "apps";
        kind = "overview";
        nav = "Apps";
    elseif source == "reference/README.md"
        id = "api";
        output = "reference/index.html";
        kind = "reference";
        nav = "API Reference";
    elseif source == "framework/README.md"
        id = "framework";
        kind = "explanation";
        nav = "App Framework";
        components = "labkit.app";
    elseif startsWith(source, "framework/")
        group = pathGroup(source, "framework");
        if group == "Guides"
            group = "Framework Guides";
        elseif group == "Compatibility"
            group = "Framework Compatibility";
        end
        nav = ["App Framework"; group];
        components = frameworkComponents(source);
    elseif source == "history/README.md"
        id = "history";
        kind = "history index";
        nav = "History";
    elseif source == "development/README.md"
        id = "development";
        kind = "overview";
        nav = "Development";
    elseif startsWith(source, "development/")
        nav = ["Development"; pathGroup(source, "development")];
    elseif startsWith(source, "libraries/")
        nav = "Libraries";
        kind = "reference";
        parts = split(source, "/");
        if numel(parts) > 1
            components = "labkit." + replace(parts(2), "-", ".");
        end
    elseif source == "apps/labkit-core/launcher/README.md"
        id = "launcher";
        kind = "app manual";
        nav = ["Apps"; "LabKit Core"];
        components = "labkit_launcher";
    end
end

function group = pathGroup(source, root)
    parts = split(extractAfter(source, string(root) + "/"), "/");
    if numel(parts) < 2
        group = "General";
        return;
    end
    group = titleCasePathToken(parts(1));
end

function value = titleCasePathToken(value)
    words = split(replace(string(value), "-", " "));
    for k = 1:numel(words)
        if k > 1 && any(words(k) == ["and", "or", "the"])
            continue;
        end
        words(k) = upper(extractBefore(words(k), 2)) + extractAfter(words(k), 1);
    end
    value = strjoin(words, " ");
end

function components = frameworkComponents(source)
    if contains(source, "/runtime")
        components = "labkit.app";
    elseif contains(source, "/contracts")
        components = "labkit.contract";
    else
        components = "labkit.app";
    end
end

function words = pathWords(source)
    words = split(replace(erase(string(source), [".md", "README"]), ...
        ["/", "-", "_"], " "));
    words = words(strlength(words) > 0);
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
        record = parseLabKitHistoryRecord(fileread(filepath), source);
        historyId = record.id;
        historyDate = record.date;
        historySequence = record.sequence;
        changeType = record.type;
        compatibility = record.compatibility;
        componentLines = record.components;
        components = strings(numel(componentLines), 1);
        for iLine = 1:numel(componentLines)
            token = regexp(componentLines(iLine), ...
                '^`([^`]+)`', "tokens", "once");
            if isempty(token)
                error("LabKit:Docs:InvalidHistory", ...
                    "History page has malformed component metadata: %s", source);
            end
            components(iLine, 1) = string(token{1});
        end
        raw = struct( ...
            "id", "history-" + historyId, ...
            "source", source, ...
            "output", erase(source, ".md") + ".html", ...
            "title", record.title, ...
            "kind", "history", ...
            "nav", strings(0, 1), ...
            "order", 1000, ...
            "keywords", [historyId; historyDate; string(historySequence); ...
                changeType; compatibility; components; record.scopes], ...
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

function apps = discoverPublicApps(repoRoot, sourceRoot)
    oldPath = path;
    cleanup = onCleanup(@() path(oldPath));
    addpath(repoRoot, "-begin");
    catalog = labkit_launcher("list");
    clear cleanup
    required = ["Command", "DisplayName", "Family", "Visibility", "Folder", ...
        "Description"];
    if ~istable(catalog) || ~all(ismember(required, ...
            string(catalog.Properties.VariableNames)))
        error("LabKit:Docs:InvalidAppDiscovery", ...
            "labkit_launcher(""list"") did not return the required App metadata.");
    end
    catalog = catalog(string(catalog.Visibility) == "public", :);
    template = struct("id", "", "command", "", "family", "", ...
        "familyTitle", "", "folder", "", "source", "", "output", "", ...
        "familySource", "", "description", "");
    apps = repmat(template, height(catalog), 1);
    appRoot = string(fullfile(repoRoot, "apps")) + filesep;
    for k = 1:height(catalog)
        folder = string(catalog.Folder(k));
        relativeFolder = replace(extractAfter(folder, appRoot), filesep, "/");
        parts = split(relativeFolder, "/");
        if numel(parts) ~= 2
            error("LabKit:Docs:InvalidAppFolder", ...
                "Public App folder must be apps/<family>/<app>: %s", folder);
        end
        id = replace(parts(2), "_", "-");
        manuals = dir(fullfile(sourceRoot, "apps", "*", id, "README.md"));
        if numel(manuals) ~= 1
            error("LabKit:Docs:MissingAppManual", ...
                ["Discovered App must have exactly one manual at " ...
                "docs/apps/<family>/%s/README.md."], id);
        end
        family = string(manuals(1).folder);
        family = replace(extractBefore(extractAfter(family, ...
            string(sourceRoot) + filesep + "apps" + filesep), filesep), ...
            filesep, "/");
        source = "apps/" + family + "/" + id + "/README.md";
        familySource = "apps/" + family + "/README.md";
        if ~isfile(fullfile(sourceRoot, familySource))
            error("LabKit:Docs:MissingAppFamilyManual", ...
                "Discovered App family has no manual: %s", familySource);
        end
        familyTitle = markdownTitle(string(fileread( ...
            fullfile(sourceRoot, familySource))), familySource);
        if endsWith(familyTitle, " Apps")
            familyTitle = extractBefore(familyTitle, ...
                strlength(familyTitle) - strlength(" Apps") + 1);
        end
        apps(k) = struct( ...
            "id", char(id), ...
            "command", char(string(catalog.Command(k))), ...
            "family", char(family), ...
            "familyTitle", char(familyTitle), ...
            "folder", char(relativeFolder), ...
            "source", char(source), ...
            "output", char("apps/" + family + "/" + id + ".html"), ...
            "familySource", char(familySource), ...
            "description", char(string(catalog.Description(k))));
    end
    assertUnique(string({apps.id}), "app id");
    assertUnique(string({apps.command}), "app command");
end

function api = discoverLabKitPublicApi(repoRoot)
    root = fullfile(repoRoot, "+labkit");
    entries = dir(fullfile(root, "**", "*.m"));
    api = repmat(emptyApi(), numel(entries), 1);
    apiCount = 0;
    for k = 1:numel(entries)
        filepath = string(fullfile(entries(k).folder, entries(k).name));
        if contains(filepath, filesep + "private" + filesep)
            continue;
        end
        if contains(filepath, filesep + "+internal" + filesep)
            continue;
        end
        if contains(filepath, filesep + "@")
            continue;
        end
        if isHiddenClassFile(filepath)
            continue;
        end
        item = readApiItem(repoRoot, filepath, "library", "labkit");
        apiCount = apiCount + 1;
        api(apiCount, 1) = item;
    end
    api = api(1:apiCount);
    [~, order] = sort(string({api.symbol}));
    api = api(order);
end

function tf = isHiddenClassFile(filepath)
    lines = strip(readlines(filepath, "EmptyLineRule", "skip"));
    lines = lines(~startsWith(lines, "%"));
    tf = ~isempty(lines) && startsWith(lines(1), "classdef") && ...
        contains(lines(1), "Hidden");
end

function api = discoverAppPublicApi(repoRoot, apps)
    entries = dir(fullfile(repoRoot, "apps", "**", "*.m"));
    api = repmat(emptyApi(), numel(entries), 1);
    apiCount = 0;
    for k = 1:numel(entries)
        filepath = string(fullfile(entries(k).folder, entries(k).name));
        text = string(fileread(filepath));
        if ~hasPublicAppHelpContract(text)
            continue;
        end
        relative = replace(extractAfter(filepath, string(repoRoot) + filesep), ...
            filesep, "/");
        if contains("/" + relative + "/", "/private/")
            error("LabKit:Docs:PrivateAppApi", ...
                "Private helpers cannot carry the App API marker: %s", relative);
        end
        parts = split(relative, "/");
        if numel(parts) < 4
            error("LabKit:Docs:InvalidAppApi", ...
                "Marked App API is outside an App package: %s", relative);
        end
        appId = replace(parts(3), "_", "-");
        appIndex = find(string({apps.id}) == appId, 1);
        if isempty(appIndex)
            error("LabKit:Docs:UnknownAppApiOwner", ...
                "Marked App API has no discovered public App owner: %s", relative);
        end
        owner = replace(appId, "-", "_");
        item = readApiItem(repoRoot, filepath, "app", owner);
        item.family = char(string(apps(appIndex).familyTitle));
        apiCount = apiCount + 1;
        api(apiCount, 1) = item;
    end
    api = api(1:apiCount);
end

function tf = hasPublicAppHelpContract(text)
    required = [ ...
        "^%\s+(?:Usage|Syntax):\s*$"
        "^%\s+Inputs:\s*$"
        "^%\s+Outputs:\s*$"
        "^%\s+(?:Errors|Failure Behavior):\s*$"
        "^%\s+See also\s+\S+"];
    tf = true;
    for k = 1:numel(required)
        if isempty(regexp(char(text), required(k), "once", "lineanchors"))
            tf = false;
            return;
        end
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
    functionStart = find(startsWith(strtrim(lines), "function"), 1);
    classStart = find(startsWith(strtrim(lines), "classdef"), 1);
    starts = [functionStart, classStart];
    starts = starts(~isnan(starts) & starts > 0);
    if isempty(starts)
        start = [];
    else
        start = min(starts);
    end
    if isempty(start)
        error("LabKit:Docs:MissingDeclaration", ...
            "Public API file has no function or class declaration: %s", ...
            relative);
    end
    finish = start;
    while finish < numel(lines) && endsWith(strip(lines(finish)), "...")
        finish = finish + 1;
    end
    signature = strjoin(strip(lines(start:finish)), newline);
    leadingHelp = leadingCommentBlock(lines, start);
    helpLines = strings(max(numel(lines) - finish, 0), 1);
    helpLineCount = 0;
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
        helpLineCount = helpLineCount + 1;
        helpLines(helpLineCount, 1) = text;
        index = index + 1;
    end
    helpLines = helpLines(1:helpLineCount);
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
    comments = strings(max(functionStart - 1, 0), 1);
    commentCount = 0;
    for k = 1:(functionStart - 1)
        trimmed = strtrim(lines(k));
        if startsWith(trimmed, "%")
            text = extractAfter(trimmed, 1);
            if startsWith(text, " ")
                text = extractAfter(text, 1);
            end
            commentCount = commentCount + 1;
            comments(commentCount, 1) = text;
        elseif strlength(trimmed) > 0
            commentCount = 0;
        end
    end
    comments = comments(1:commentCount);
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
