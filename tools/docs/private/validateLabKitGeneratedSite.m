function validateLabKitGeneratedSite(root, model)
%VALIDATELABKITGENERATEDSITE Reject incomplete or malformed site output.
% Expected caller: renderLabKitDocs before generated output is synchronized.
% Inputs: complete staging tree and the validated source model used to render it.
% Output: none; throws when output breaks a structural or discovery contract.
% Side effects: reads generated HTML and search JSON only.

    files = listLabKitDocTreeFiles(root);
    pages = files(endsWith(files, ".html"));
    expectedNarrative = string({model.pages.output}).';
    expectedApi = apiOutputs(model.api);
    requireOutputs(files, [expectedNarrative; expectedApi]);

    pageText = cell(numel(pages), 1);
    pageIds = cell(numel(pages), 1);
    pageEdges = cell(numel(pages), 1);
    for k = 1:numel(pages)
        text = string(fileread(fullfile(root, pages(k))));
        pageText{k} = text;
        pageIds{k} = validatePageStructure(pages(k), text);
    end
    for k = 1:numel(pages)
        pageEdges{k} = validatePageLinks( ...
            pages(k), pageText{k}, files, pages, pageIds);
    end

    validateReachability(pages, pageEdges);
    validateSearch(root, expectedNarrative, expectedApi);
    validateDocumentationMap(pages, pageText);
    validateApiDiscovery(model, pages, pageText, pageEdges, expectedApi);
end

function requireOutputs(files, expected)
    missing = expected(~ismember(expected, files));
    if ~isempty(missing)
        error("LabKit:Docs:MissingGeneratedOutput", ...
            "Documentation output is missing expected page %s.", missing(1));
    end
end

function ids = validatePageStructure(page, text)
    requireCount(page, text, '<main(?:\s|>)', 1, "main landmark");
    requireCount(page, text, '<h1(?:\s|>)', 1, "level-one heading");
    requireCount(page, text, '<nav class="product-nav"', 1, ...
        "product navigation");
    requireCount(page, text, '<footer(?:\s|>)', 1, "footer");
    if page ~= "index.html"
        requireCount(page, text, '<nav class="breadcrumbs"', 1, ...
            "breadcrumb trail");
    end

    ids = firstTokens(regexp(char(text), ...
        '\sid="([^"]+)"', 'tokens'));
    if numel(unique(ids)) ~= numel(ids)
        [names, ~, groups] = unique(ids);
        counts = accumarray(groups, 1);
        duplicate = names(find(counts > 1, 1));
        error("LabKit:Docs:DuplicateGeneratedId", ...
            "Generated page %s repeats HTML id %s.", page, duplicate);
    end

    levels = double(firstTokens(regexp(char(text), ...
        '<h([1-6])(?:\s|>)', 'tokens')));
    jumps = find(diff(levels) > 1, 1);
    if ~isempty(jumps)
        error("LabKit:Docs:InvalidHeadingHierarchy", ...
            "Generated page %s jumps from h%d to h%d.", ...
            page, levels(jumps), levels(jumps + 1));
    end
    validateTables(page, text);
end

function requireCount(page, text, expression, expected, label)
    actual = numel(regexp(char(text), expression, 'match'));
    if actual ~= expected
        error("LabKit:Docs:InvalidGeneratedStructure", ...
            "Generated page %s contains %d %s instances; expected %d.", ...
            page, actual, label, expected);
    end
end

function validateTables(page, text)
    tables = regexp(char(text), '(?s)<table\b[^>]*>.*?</table>', 'match');
    for k = 1:numel(tables)
        table = string(tables{k});
        if ~contains(table, "<thead") || ~contains(table, "<tbody") || ...
                isempty(regexp(char(table), '<tbody[^>]*>\s*<tr', 'once'))
            error("LabKit:Docs:InvalidGeneratedTable", ...
                "Generated page %s contains a table without headings or rows.", ...
                page);
        end
    end
end

function edges = validatePageLinks(source, text, files, pages, pageIds)
    hrefs = firstTokens(regexp(char(text), 'href="([^"]+)"', 'tokens'));
    edges = strings(numel(hrefs), 1);
    edgeCount = 0;
    for k = 1:numel(hrefs)
        href = hrefs(k);
        if isExternal(href)
            continue;
        end
        [path, fragment] = splitHref(href);
        if strlength(path) == 0
            target = source;
        else
            target = resolveTarget(source, path);
        end
        if ~any(files == target)
            error("LabKit:Docs:BrokenGeneratedLink", ...
                "Generated page %s links to missing output %s via %s.", ...
                source, target, href);
        end
        if endsWith(target, ".html")
            edgeCount = edgeCount + 1;
            edges(edgeCount) = target;
        end
        if strlength(fragment) > 0 && endsWith(target, ".html")
            targetIndex = find(pages == target, 1);
            if ~any(pageIds{targetIndex} == fragment)
                error("LabKit:Docs:BrokenGeneratedAnchor", ...
                    "Generated page %s links to missing anchor %s in %s.", ...
                    source, fragment, target);
            end
        end
    end
    edges = edges(1:edgeCount);
    edges = unique(edges, "stable");
    edges = edges(ismember(edges, pages));
end

function external = isExternal(href)
    external = startsWith(href, "//") || ...
        ~isempty(regexp(char(href), ...
        '^[A-Za-z][A-Za-z0-9+.-]*:', 'once'));
end

function [path, fragment] = splitHref(href)
    href = string(href);
    fragment = "";
    if contains(href, "#")
        fragment = extractAfter(href, "#");
        path = extractBefore(href, "#");
    else
        path = href;
    end
    path = extractBefore(path + "?", "?");
end

function target = resolveTarget(source, href)
    href = replace(string(href), "\", "/");
    if startsWith(href, "/")
        base = strings(0, 1);
        href = extractAfter(href, 1);
    else
        folder = replace(string(fileparts(char(source))), "\", "/");
        base = splitPath(folder);
    end
    parts = [base; split(href, "/")];
    normalized = strings(numel(parts), 1);
    count = 0;
    for k = 1:numel(parts)
        part = parts(k);
        if strlength(part) == 0 || part == "."
            continue;
        elseif part == ".."
            if count == 0
                error("LabKit:Docs:GeneratedLinkEscapesSite", ...
                    "Generated page %s has a link outside the site: %s.", ...
                    source, href);
            end
            count = count - 1;
        else
            count = count + 1;
            normalized(count) = part;
        end
    end
    target = strjoin(normalized(1:count), "/");
end

function parts = splitPath(path)
    if strlength(path) == 0 || path == "."
        parts = strings(0, 1);
    else
        parts = split(path, "/");
        parts = parts(strlength(parts) > 0);
    end
end

function validateReachability(pages, pageEdges)
    start = find(pages == "index.html", 1);
    if isempty(start)
        error("LabKit:Docs:MissingDocumentationHome", ...
            "Generated documentation has no index.html home page.");
    end
    visited = false(numel(pages), 1);
    discovered = false(numel(pages), 1);
    discovered(start) = true;
    pending = zeros(numel(pages), 1);
    pending(1) = start;
    head = 1;
    tail = 1;
    while head <= tail
        index = pending(head);
        head = head + 1;
        visited(index) = true;
        targets = pageEdges{index};
        next = find(ismember(pages, targets) & ~discovered);
        if ~isempty(next)
            pending(tail + (1:numel(next))) = next;
            tail = tail + numel(next);
            discovered(next) = true;
        end
    end
    if any(~visited)
        missing = pages(find(~visited, 1));
        error("LabKit:Docs:UnreachableGeneratedPage", ...
            "Generated page %s is not reachable from documentation home.", ...
            missing);
    end
end

function validateSearch(root, expectedNarrative, expectedApi)
    path = fullfile(root, "assets", "search-index.json");
    if ~isfile(path)
        error("LabKit:Docs:MissingSearchIndex", ...
            "Generated documentation has no search index.");
    end
    entries = jsondecode(fileread(path));
    actual = string({entries.url}).';
    expected = [expectedNarrative; expectedApi];
    if numel(unique(actual)) ~= numel(actual) || ...
            ~isempty(setxor(actual, expected))
        error("LabKit:Docs:InvalidSearchCoverage", ...
            "Search index does not contain exactly the current narrative and API pages.");
    end
end

function validateDocumentationMap(pages, pageText)
    index = find(pages == "map/index.html", 1);
    if isempty(index)
        error("LabKit:Docs:MissingDocumentationMap", ...
            "Generated documentation has no structural map.");
    end
    text = pageText{index};
    for id = ["use", "develop", "reference", "changes"]
        if ~contains(text, "id=""" + id + """")
            error("LabKit:Docs:IncompleteDocumentationMap", ...
                "Documentation map has no %s section.", id);
        end
    end
end

function validateApiDiscovery(model, pages, pageText, pageEdges, expectedApi)
    referencePage = model.pages(string({model.pages.id}) == "reference");
    if numel(referencePage) ~= 1
        error("LabKit:Docs:MissingReferenceLanding", ...
            "Documentation model must contain one Reference landing page.");
    end
    referenceIndex = find(pages == string(referencePage.output), 1);
    referenceText = pageText{referenceIndex};
    if ~contains(referenceText, 'id="browse-by-module"')
        error("LabKit:Docs:MissingApiCatalog", ...
            "Reference landing page has no generated module catalog.");
    end

    symbols = string({model.api.symbol}).';
    origins = string({model.api.origin}).';
    referenceOwned = origins == "app" | ~startsWith(symbols, "labkit.app");
    missingReference = expectedApi(referenceOwned & ...
        ~ismember(expectedApi, pageEdges{referenceIndex}));
    if ~isempty(missingReference)
        error("LabKit:Docs:IncompleteApiCatalog", ...
            "Reference landing page does not link public API %s.", ...
            missingReference(1));
    end

    narrativeIndices = find(ismember(pages, string({model.pages.output})));
    edgeCounts = cellfun(@numel, pageEdges(narrativeIndices));
    linked = strings(sum(edgeCounts), 1);
    offset = 0;
    for index = narrativeIndices.'
        additions = pageEdges{index};
        linked(offset + (1:numel(additions))) = additions;
        offset = offset + numel(additions);
    end
    missing = expectedApi(~ismember(expectedApi, unique(linked)));
    if ~isempty(missing)
        error("LabKit:Docs:UndiscoverablePublicApi", ...
            "Public API page %s has no link from a current narrative page.", ...
            missing(1));
    end
end

function outputs = apiOutputs(api)
    symbols = string({api.symbol}).';
    outputs = "reference/api/" + replace(symbols, ".", "/") + ".html";
end

function values = firstTokens(tokens)
    values = strings(numel(tokens), 1);
    for k = 1:numel(tokens)
        values(k) = string(tokens{k}{1});
    end
end
