function [html, plainText] = renderLabKitApiCatalog(model, page)
%RENDERLABKITAPICATALOG Add source-derived API discovery to narrative pages.
% Expected caller: renderLabKitDocs for every current narrative page.
% Inputs: validated documentation model and current narrative page record.
% Outputs: optional HTML catalog and searchable plain text.

    if page.id == "reference"
        [html, plainText] = referenceCatalog(model, page.output);
        return;
    end

    api = model.api;
    if page.output == "develop/framework/app-sdk-api.html"
        matches = startsWith(string({api.symbol}).', "labkit.app");
    elseif page.kind == "app"
        owner = replace(extractAfter(page.id, "app-"), "-", "_");
        matches = string({api.origin}).' == "app" & ...
            string({api.owner}).' == owner;
    else
        matches = packageGuideMatches(api, page.output);
        if ~any(matches)
            matches = mentionedApiMatches(api, page.sourcePath);
        end
    end

    items = sortedItems(api(matches));
    if isempty(items)
        html = "";
        plainText = "";
        return;
    end
    if page.output == "develop/framework/app-sdk-api.html"
        [content, plainText] = appSdkGroups(items, page.output);
        heading = "Complete App SDK API";
    else
        [content, words] = apiTable(items, page.output);
        plainText = strjoin(words, " ");
        heading = "Functions And API";
    end
    html = "<section class=""page-api-links""><h2 id=""functions-and-api"">" + ...
        heading + "</h2><p>Open a function for exact MATLAB syntax, " + ...
        "arguments, outputs, behavior, and source.</p>" + content + "</section>";
end

function [html, plainText] = referenceCatalog(model, outputPath)
    groups = apiGroups(model.api);
    blocks = strings(numel(groups), 1);
    wordChunks = cell(numel(groups), 1);
    for k = 1:numel(groups)
        items = sortedItems(model.api(groups(k).indices));
        [guideTarget, guideLabel] = categoryTarget(model, items, groups(k));
        [tableHtml, words] = apiTable(items, outputPath);
        blocks(k) = "<section class=""api-group""><h3 id=""" + ...
            groups(k).id + """>" + htmlEscape(groups(k).title) + ...
            "</h3><p>" + htmlEscape(groups(k).description) + ...
            " <a href=""" + relativeWebPath(outputPath, guideTarget) + ...
            """>Read " + htmlEscape(guideLabel) + "</a>.</p>" + ...
            tableHtml + "</section>";
        wordChunks{k} = [groups(k).title; groups(k).description; ...
            guideLabel; words];
    end
    words = vertcat(wordChunks{:});
    html = "<section class=""api-catalog""><h2 id=""browse-by-module"">" + ...
        "Browse By Module</h2><p>Each module begins with its current guide " + ...
        "and lists every supported public function discovered from MATLAB " + ...
        "source.</p>" + strjoin(blocks, newline) + "</section>";
    plainText = strjoin(words, " ");
end

function matches = packageGuideMatches(api, outputPath)
    matches = false(numel(api), 1);
    token = regexp(char(outputPath), ...
        '^develop/libraries/([^/]+)/index[.]html$', 'tokens', 'once');
    if ~isempty(token)
        prefix = "labkit." + string(token{1});
        symbols = string({api.symbol}).';
        matches = symbols == prefix | startsWith(symbols, prefix + ".");
    elseif outputPath == "develop/framework/compatibility/contracts.html"
        matches = startsWith(string({api.symbol}).', "labkit.contract.");
    end
end

function matches = mentionedApiMatches(api, sourcePath)
    text = string(fileread(sourcePath));
    symbols = string({api.symbol}).';
    matches = false(numel(symbols), 1);
    for k = 1:numel(symbols)
        matches(k) = contains(text, symbols(k));
    end
end

function items = sortedItems(items)
    if isempty(items)
        return;
    end
    [~, order] = sort(string({items.symbol}));
    items = items(order);
end

function [html, plainText] = appSdkGroups(items, outputPath)
    symbols = string({items.symbol});
    groups = strings(numel(items), 1);
    for k = 1:numel(items)
        parts = split(symbols(k), ".");
        if numel(parts) == 2
            groups(k) = "Core";
        else
            groups(k) = parts(3);
        end
    end
    preferred = ["Core", "layout", "view", "event", "interaction", ...
        "plot", "project", "result", "dialog", "diagnostic"];
    present = unique(groups, "stable").';
    order = [preferred(ismember(preferred, present)), ...
        present(~ismember(present, preferred))];
    blocks = strings(numel(order), 1);
    wordChunks = cell(numel(order), 1);
    for k = 1:numel(order)
        members = items(groups == order(k));
        [tableHtml, words] = apiTable(members, outputPath);
        blocks(k) = "<section class=""api-group""><h3>" + ...
            htmlEscape(displayGroup(order(k))) + "</h3>" + ...
            tableHtml + "</section>";
        wordChunks{k} = words;
    end
    html = strjoin(blocks, newline);
    plainText = strjoin(vertcat(wordChunks{:}), " ");
end

function [html, words] = apiTable(items, outputPath)
    rows = strings(numel(items), 1);
    words = strings(numel(items), 1);
    for k = 1:numel(items)
        target = apiOutput(items(k));
        summary = regexprep(string(items(k).summary), ...
            '^[A-Z][A-Z0-9_]*\s+', '');
        rows(k) = "<tr><td><a href=""" + ...
            relativeWebPath(outputPath, target) + """><code>" + ...
            htmlEscape(items(k).symbol) + "</code></a></td><td>" + ...
            htmlEscape(summary) + "</td></tr>";
        words(k) = string(items(k).symbol) + " " + summary;
    end
    html = "<div class=""table-wrap""><table class=""api-table"">" + ...
        "<thead><tr><th>Function</th><th>Purpose</th></tr></thead><tbody>" + ...
        strjoin(rows, "") + "</tbody></table></div>";
end

function output = apiOutput(item)
    output = "reference/api/" + ...
        replace(string(item.symbol), ".", "/") + ".html";
end

function [target, label] = categoryTarget(model, items, group)
    first = items(1);
    if string(first.origin) == "app"
        pageId = "app-" + replace(string(first.owner), "_", "-");
        index = find(string({model.pages.id}) == pageId, 1);
        if isempty(index)
            error("LabKit:Docs:MissingApiGuide", ...
                "Public App API group %s has no current App guide.", group.id);
        end
        target = string(model.pages(index).output);
        label = string(model.pages(index).title);
        return;
    end
    key = erase(group.id, "app-");
    if key == "labkit-contract"
        target = "develop/framework/compatibility/contracts.html";
        label = "Framework Compatibility";
    else
        parts = split(string(first.symbol), ".");
        target = "develop/libraries/" + parts(2) + "/index.html";
        label = group.title + " guide";
    end
end

function groups = apiGroups(api)
    symbols = string({api.symbol});
    origin = string({api.origin});
    libraryIndices = find(origin == "library" & ...
        ~startsWith(symbols, "labkit.app"));
    libraryKeys = strings(numel(libraryIndices), 1);
    for k = 1:numel(libraryIndices)
        parts = split(symbols(libraryIndices(k)), ".");
        depth = min(numel(parts) - 1, 3);
        libraryKeys(k) = strjoin(parts(1:depth), ".");
    end
    keys = unique(libraryKeys, "stable");
    appIndices = find(origin == "app");
    owners = string({api(appIndices).owner});
    ownerKeys = unique(owners, "stable");
    template = struct("id", "", "title", "", "description", "", ...
        "indices", []);
    groups = repmat(template, numel(keys) + numel(ownerKeys), 1);
    groupCount = 0;
    for k = 1:numel(keys)
        key = keys(k);
        groupCount = groupCount + 1;
        groups(groupCount) = struct( ...
            "id", slug(key), ...
            "title", libraryTitle(key), ...
            "description", libraryDescription(key), ...
            "indices", libraryIndices(libraryKeys == key).');
    end
    for k = 1:numel(ownerKeys)
        owner = ownerKeys(k);
        indices = appIndices(owners == owner);
        family = string(api(indices(1)).family);
        groupCount = groupCount + 1;
        groups(groupCount) = struct( ...
            "id", "app-" + slug(owner), ...
            "title", humanize(owner) + " App API", ...
            "description", "Supported GUI-free operations owned by the " + ...
                humanize(owner) + " app in the " + family + " family.", ...
            "indices", indices(:).');
    end
    groups = groups(1:groupCount);
end

function title = libraryTitle(key)
    if key == "labkit.contract"
        title = "Framework Compatibility (labkit.contract)";
    else
        title = key;
    end
end

function description = libraryDescription(key)
    switch key
        case "labkit.contract"
            description = "Version and MathWorks-product requirement contracts.";
        case "labkit.image"
            description = "Generic image file IO, normalization, resizing, filtering, and enhancement primitives.";
        case "labkit.thermal"
            description = "Radiometric image inspection, conversion, reading, and rendering.";
        case "labkit.dta"
            description = "Gamry DTA discovery, parsing, curve access, and pulse detection.";
        case "labkit.rhs"
            description = "Intan RHS discovery, indexing, inspection, and bounded waveform reads.";
        case "labkit.biosignal"
            description = "Recording import, channel access, filtering, events, templates, and measurements.";
        case "labkit.mark10"
            description = "Mark-10 discovery, communication, settings, samples, and units.";
        otherwise
            description = "Public functions in " + key + ".";
    end
end

function label = displayGroup(group)
    if group == "Core"
        label = "Core";
    else
        label = "labkit.app." + group;
    end
end

function value = humanize(value)
    value = replace(string(value), "_", " ");
    words = split(value);
    for k = 1:numel(words)
        if strlength(words(k)) > 0
            words(k) = upper(extractBefore(words(k), 2)) + ...
                extractAfter(words(k), 1);
        end
    end
    value = strjoin(words, " ");
end

function value = slug(value)
    value = lower(regexprep(string(value), '[^A-Za-z0-9]+', '-'));
    value = strip(value, "-");
end

function text = htmlEscape(text)
    text = replace(string(text), "&", "&amp;");
    text = replace(text, "<", "&lt;");
    text = replace(text, ">", "&gt;");
    text = replace(text, """", "&quot;");
end
