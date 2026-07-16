function html = renderLabKitApiBody(model, item, outputPath)
%RENDERLABKITAPIBODY Render one source-bound MATLAB API reference page.
% Expected caller: documentation renderer for one discovered public function.
% Inputs: documentation model, API record, and generated output path.
% Output: structured HTML reference body.

    indexUrl = relativeWebPath(outputPath, "reference/index.html");
    [ownerTitle, ownerTarget] = ownerPage(model, item);
    context = "<p class=""api-context""><a href=""" + indexUrl + ...
        """>API Reference</a>";
    if strlength(ownerTarget) > 0
        context = context + " &rsaquo; <a href=""" + ...
            relativeWebPath(outputPath, ownerTarget) + """>" + ...
            htmlEscape(ownerTitle) + "</a>";
    end
    context = context + "</p>";

    sourceUrl = model.repositoryUrl + "/blob/main/" + item.source;
    summary = cleanSummary(item.summary);
    contractHtml = renderHelpSections(item.helpText, item.summary);
    relatedHtml = renderRelatedApis(model.api, item, outputPath);
    html = strjoin([ ...
        context
        "<h1><code>" + htmlEscape(item.symbol) + "</code></h1>"
        "<p class=""lead"">" + htmlEscape(summary) + "</p>"
        "<h2 id=""syntax"">Syntax</h2>"
        "<pre><code class=""language-matlab"">" + ...
            htmlEscape(item.signature) + "</code></pre>"
        contractHtml
        relatedHtml
        "<h2 id=""source"">Source</h2>"
        "<p>This page is generated from the MATLAB help text in " + ...
            "<a href=""" + htmlEscape(sourceUrl) + """><code>" + ...
            htmlEscape(item.source) + "</code></a>.</p>"], newline);
end

function html = renderHelpSections(helpText, summaryLine)
    lines = splitlines(string(helpText));
    if ~isempty(lines) && strip(lines(1)) == strip(string(summaryLine))
        lines(1) = [];
    end
    sections = parseSections(lines);
    blocks = strings(0, 1);
    for k = 1:numel(sections)
        content = stripEmptyEdges(sections(k).lines);
        if isempty(content)
            continue;
        end
        title = displaySectionTitle(sections(k).name);
        id = slug(title);
        blocks(end + 1, 1) = "<section class=""api-section""><h2 id=""" + ...
            id + """>" + htmlEscape(title) + "</h2>" + ...
            renderSectionContent(title, content) + "</section>";
    end
    html = strjoin(blocks, newline);
end

function sections = parseSections(lines)
    template = struct("name", "Description", "lines", strings(0, 1));
    sections = template;
    current = 1;
    for k = 1:numel(lines)
        line = lines(k);
        trimmed = strip(line);
        isHeader = line == trimmed && ~isempty(regexp(char(trimmed), ...
            '^[A-Za-z][A-Za-z0-9 /&-]+:$', 'once'));
        if isHeader
            name = extractBefore(trimmed, strlength(trimmed));
            if isempty(sections(current).lines) && ...
                    sections(current).name == "Description"
                sections(current).name = name;
            else
                sections(end + 1, 1) = template;
                current = numel(sections);
                sections(current).name = name;
            end
        else
            sections(current).lines(end + 1, 1) = line;
        end
    end
end

function html = renderSectionContent(title, lines)
    codeTitles = ["Usage", "App-facing Contract", "Example", "Examples", ...
        "Internal Usage"];
    if any(title == codeTitles)
        html = "<pre><code class=""language-matlab"">" + ...
            htmlEscape(strjoin(strip(lines), newline)) + "</code></pre>";
        return;
    end
    definitionTitles = ["Inputs", "Input", "Outputs", "Output", ...
        "Options", "Parameters", "Fields", "Input Fields", ...
        "Output Fields", "Calibration Fields", "Name-Value Arguments", ...
        "Inputs/Outputs", "Returned Options", ...
        "Returned Editor API", "Callback Events", "Mode Values"];
    if any(title == definitionTitles)
        html = renderDefinitions(lines);
        return;
    end
    html = renderParagraphs(lines);
end

function html = renderDefinitions(lines)
    entries = repmat(struct("term", "", "description", ""), 0, 1);
    preface = strings(0, 1);
    current = 0;
    for k = 1:numel(lines)
        token = regexp(char(lines(k)), ...
            '^\s{2,}([A-Za-z][A-Za-z0-9_.]*(?:\([^)]*\))?)\s+-\s+(.*)$', ...
            'tokens', 'once');
        if ~isempty(token)
            entries(end + 1, 1) = struct("term", string(token{1}), ...
                "description", string(token{2}));
            current = numel(entries);
        elseif current > 0 && strlength(strip(lines(k))) > 0
            entries(current).description = entries(current).description + " " + ...
                strip(lines(k));
        elseif current == 0
            preface(end + 1, 1) = lines(k);
        end
    end
    parts = strings(0, 1);
    if any(strlength(strip(preface)) > 0)
        parts(end + 1, 1) = renderParagraphs(preface);
    end
    if ~isempty(entries)
        rows = strings(numel(entries), 1);
        for k = 1:numel(entries)
            rows(k) = "<div class=""argument""><dt><code>" + ...
                htmlEscape(entries(k).term) + "</code></dt><dd>" + ...
                htmlEscape(entries(k).description) + "</dd></div>";
        end
        parts(end + 1, 1) = "<dl class=""argument-list"">" + ...
            strjoin(rows, "") + "</dl>";
    end
    html = strjoin(parts, newline);
end

function html = renderParagraphs(lines)
    text = strip(strjoin(lines, newline));
    paragraphs = regexp(char(text), '\n\s*\n', 'split');
    blocks = strings(0, 1);
    for k = 1:numel(paragraphs)
        value = strip(regexprep(string(paragraphs{k}), '\s+', ' '));
        if strlength(value) > 0
            blocks(end + 1, 1) = "<p>" + htmlEscape(value) + "</p>";
        end
    end
    html = strjoin(blocks, newline);
end

function html = renderRelatedApis(api, item, outputPath)
    related = relatedApiItems(api, item.symbol);
    if isempty(related)
        html = "";
        return;
    end
    rows = strings(numel(related), 1);
    for k = 1:numel(related)
        target = "reference/api/" + replace(related(k).symbol, ".", "/") + ".html";
        rows(k) = "<li><a href=""" + relativeWebPath(outputPath, target) + ...
            """><code>" + htmlEscape(related(k).symbol) + "</code></a> — " + ...
            htmlEscape(cleanSummary(related(k).summary)) + "</li>";
    end
    html = "<h2 id=""related-apis"">Related APIs</h2><ul>" + ...
        strjoin(rows, "") + "</ul>";
end

function [title, target] = ownerPage(model, item)
    title = "";
    target = "";
    pages = model.pages;
    if string(item.origin) == "app"
        id = "app-" + replace(string(item.owner), "_", "-");
        index = find(string({pages.id}) == id, 1);
    else
        symbol = string(item.symbol);
        candidates = false(numel(pages), 1);
        specificity = zeros(numel(pages), 1);
        for k = 1:numel(pages)
            if string(pages(k).kind) == "history"
                continue;
            end
            components = string(pages(k).components);
            for iComponent = 1:numel(components)
                component = components(iComponent);
                if startsWith(component, "labkit.") && ...
                        (symbol == component || startsWith(symbol, component + "."))
                    candidates(k) = true;
                    specificity(k) = max(specificity(k), strlength(component));
                end
            end
        end
        indices = find(candidates);
        if isempty(indices)
            index = [];
        else
            [~, local] = max(specificity(indices));
            index = indices(local);
        end
    end
    if ~isempty(index)
        title = string(pages(index).title);
        target = string(pages(index).output);
    end
end

function related = relatedApiItems(api, symbol)
    parts = split(string(symbol), ".");
    prefix = strjoin(parts(1:max(1, numel(parts) - 1)), ".") + ".";
    symbols = string({api.symbol});
    matches = startsWith(symbols, prefix) & symbols ~= string(symbol);
    candidates = api(matches);
    related = candidates(1:min(8, numel(candidates)));
end

function value = displaySectionTitle(value)
    value = string(value);
    switch lower(value)
        case "app-facing contract"
            value = "Usage";
        case "internal contract"
            value = "Implementation Notes";
        case "expected caller"
            value = "Caller";
        case "expected callers"
            value = "Callers";
        otherwise
            words = split(value);
            for k = 1:numel(words)
                if strlength(words(k)) > 0
                    words(k) = upper(extractBefore(words(k), 2)) + ...
                        extractAfter(words(k), 1);
                end
            end
            value = strjoin(words, " ");
    end
end

function value = cleanSummary(value)
    value = regexprep(string(value), '^[A-Z][A-Z0-9_]*\s+', '');
end

function lines = stripEmptyEdges(lines)
    while ~isempty(lines) && strlength(strip(lines(1))) == 0
        lines(1) = [];
    end
    while ~isempty(lines) && strlength(strip(lines(end))) == 0
        lines(end) = [];
    end
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
