function [html, plainText] = renderLabKitMarkdown(model, page)
%RENDERLABKITMARKDOWN Render the repository's documented Markdown subset.

    lines = readlines(page.sourcePath, "EmptyLineRule", "read");
    output = strings(0, 1);
    plain = strings(0, 1);
    index = 1;
    listType = "";
    inCode = false;
    codeLanguage = "";
    codeLines = strings(0, 1);
    while index <= numel(lines)
        line = lines(index);
        trimmed = strtrim(line);
        if inCode
            if startsWith(trimmed, "```")
                output(end + 1, 1) = "<pre><code class=""language-" + ...
                    htmlEscape(codeLanguage) + """>" + ...
                    htmlEscape(strjoin(codeLines, newline)) + "</code></pre>";
                plain = [plain; codeLines];
                inCode = false;
                codeLines = strings(0, 1);
            else
                codeLines(end + 1, 1) = line;
            end
            index = index + 1;
            continue;
        end
        if startsWith(trimmed, "```")
            [output, listType] = closeList(output, listType);
            inCode = true;
            codeLanguage = strip(extractAfter(trimmed, 3));
            index = index + 1;
            continue;
        end
        if strlength(trimmed) == 0
            [output, listType] = closeList(output, listType);
            index = index + 1;
            continue;
        end
        if isTableStart(lines, index)
            [output, listType] = closeList(output, listType);
            [tableHtml, tablePlain, index] = renderTable(model, page, lines, index);
            output(end + 1, 1) = tableHtml;
            plain(end + 1, 1) = tablePlain;
            continue;
        end
        heading = regexp(char(trimmed), '^(#{1,6})\s+(.+)$', 'tokens', 'once');
        if ~isempty(heading)
            [output, listType] = closeList(output, listType);
            level = strlength(string(heading{1}));
            label = string(heading{2});
            anchor = headingAnchor(label);
            output(end + 1, 1) = "<h" + level + " id=""" + anchor + """>" + ...
                renderInline(model, page, label) + "</h" + level + ">";
            plain(end + 1, 1) = label;
            index = index + 1;
            continue;
        end
        bullet = regexp(char(line), '^\s*[-*]\s+(.+)$', 'tokens', 'once');
        numbered = regexp(char(line), '^\s*\d+[.]\s+(.+)$', 'tokens', 'once');
        if ~isempty(bullet) || ~isempty(numbered)
            wanted = "ul";
            item = bullet;
            if isempty(item)
                wanted = "ol";
                item = numbered;
            end
            [output, listType] = ensureList(output, listType, wanted);
            output(end + 1, 1) = "<li>" + ...
                renderInline(model, page, string(item{1})) + "</li>";
            plain(end + 1, 1) = string(item{1});
            index = index + 1;
            continue;
        end
        [output, listType] = closeList(output, listType);
        if startsWith(trimmed, ">")
            content = strip(extractAfter(trimmed, 1));
            output(end + 1, 1) = "<aside class=""note"">" + ...
                renderInline(model, page, content) + "</aside>";
            plain(end + 1, 1) = content;
            index = index + 1;
            continue;
        end
        if any(trimmed == ["---", "***"])
            output(end + 1, 1) = "<hr>";
            index = index + 1;
            continue;
        end

        paragraph = trimmed;
        index = index + 1;
        while index <= numel(lines) && isParagraphContinuation(lines, index)
            paragraph = paragraph + " " + strtrim(lines(index));
            index = index + 1;
        end
        output(end + 1, 1) = "<p>" + ...
            renderInline(model, page, paragraph) + "</p>";
        plain(end + 1, 1) = paragraph;
    end
    [output, ~] = closeList(output, listType);
    if inCode
        error("LabKit:Docs:UnclosedCodeFence", ...
            "Page %s has an unclosed code fence.", page.source);
    end
    html = strjoin(output, newline);
    plainText = strjoin(plain, " ");
end

function tf = isParagraphContinuation(lines, index)
    line = lines(index);
    trimmed = strtrim(line);
    tf = strlength(trimmed) > 0 && ...
        isempty(regexp(char(trimmed), '^(#{1,6})\s+', 'once')) && ...
        isempty(regexp(char(line), '^\s*[-*]\s+', 'once')) && ...
        isempty(regexp(char(line), '^\s*\d+[.]\s+', 'once')) && ...
        ~startsWith(trimmed, ["```", ">"]);
    if tf && isTableStart(lines, index)
        tf = false;
    end
end

function tf = isTableStart(lines, index)
    tf = index < numel(lines) && contains(lines(index), "|") && ...
        ~isempty(regexp(char(strtrim(lines(index + 1))), ...
        '^\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)+\|?$', 'once'));
end

function [html, plain, nextIndex] = renderTable(model, page, lines, index)
    headers = tableCells(lines(index));
    index = index + 2;
    rows = cell(0, 1);
    while index <= numel(lines) && contains(lines(index), "|") && ...
            strlength(strtrim(lines(index))) > 0
        rows{end + 1, 1} = tableCells(lines(index));
        index = index + 1;
    end
    chunks = "<div class=""table-wrap""><table><thead><tr>";
    for k = 1:numel(headers)
        chunks = chunks + "<th>" + renderInline(model, page, headers(k)) + "</th>";
    end
    chunks = chunks + "</tr></thead><tbody>";
    for r = 1:numel(rows)
        chunks = chunks + "<tr>";
        cells = rows{r};
        for c = 1:numel(headers)
            value = "";
            if c <= numel(cells)
                value = cells(c);
            end
            chunks = chunks + "<td>" + renderInline(model, page, value) + "</td>";
        end
        chunks = chunks + "</tr>";
    end
    html = chunks + "</tbody></table></div>";
    plain = strjoin([headers, rows{:}], " ");
    nextIndex = index;
end

function cells = tableCells(line)
    line = strip(string(line));
    if startsWith(line, "|")
        line = extractAfter(line, 1);
    end
    if endsWith(line, "|")
        line = extractBefore(line, strlength(line));
    end
    cells = strip(split(line, "|")).';
end

function [output, listType] = ensureList(output, listType, wanted)
    if listType == wanted
        return;
    end
    [output, listType] = closeList(output, listType);
    output(end + 1, 1) = "<" + wanted + ">";
    listType = wanted;
end

function [output, listType] = closeList(output, listType)
    if strlength(listType) > 0
        output(end + 1, 1) = "</" + listType + ">";
    end
    listType = "";
end

function html = renderInline(model, page, text)
    text = string(text);
    replacements = strings(0, 1);
    [text, replacements] = protectTokens(text, replacements, ...
        '`([^`]+)`', @(token) "<code>" + htmlEscape(token{1}) + "</code>");
    [text, replacements] = protectTokens(text, replacements, ...
        '!\[([^\]]*)\]\(([^)]+)\)', @(token) renderImage(token));
    [text, replacements] = protectTokens(text, replacements, ...
        '\[([^\]]+)\]\(([^)]+)\)', @(token) renderLink(model, page, token));
    html = htmlEscape(text);
    html = regexprep(html, '\*\*([^*]+)\*\*', '<strong>$1</strong>');
    html = regexprep(html, '(?<!\*)\*([^*]+)\*(?!\*)', '<em>$1</em>');
    for k = 1:numel(replacements)
        html = replace(html, tokenMarker(k), replacements(k));
    end
end

function [text, replacements] = protectTokens(text, replacements, pattern, renderer)
    while true
        [start, finish, tokens] = regexp(char(text), pattern, ...
            'start', 'end', 'tokens', 'once');
        if isempty(start)
            break;
        end
        replacements(end + 1, 1) = renderer(tokens);
        marker = tokenMarker(numel(replacements));
        text = extractBefore(text, start) + marker + extractAfter(text, finish);
    end
end

function marker = tokenMarker(index)
    marker = "@@LABKITDOC" + string(index) + "@@";
end

function html = renderImage(token)
    alt = htmlEscape(string(token{1}));
    source = htmlEscape(string(token{2}));
    html = "<img src=""" + source + """ alt=""" + alt + """>";
end

function html = renderLink(model, page, token)
    label = htmlEscape(string(token{1}));
    target = rewriteLink(model, page, string(token{2}));
    html = "<a href=""" + htmlEscape(target) + """>" + label + "</a>";
end

function target = rewriteLink(model, page, target)
    if startsWith(target, ["http://", "https://", "mailto:", "#"])
        return;
    end
    pieces = split(target, "#");
    path = pieces(1);
    fragment = "";
    if numel(pieces) > 1
        fragment = "#" + strjoin(pieces(2:end), "#");
    end
    if ~endsWith(lower(path), ".md")
        return;
    end
    currentFolder = fileparts(char(page.source));
    resolved = normalizeDocPath(fullfile(currentFolder, char(path)));
    sources = string({model.pages.source});
    match = find(sources == resolved, 1);
    if ~isempty(match)
        target = relativeWebPath(page.output, model.pages(match).output) + fragment;
        return;
    end
    if startsWith(resolved, "../")
        repositoryPath = extractAfter(resolved, 3);
        target = model.repositoryUrl + "/blob/main/" + repositoryPath + fragment;
    end
end

function path = normalizeDocPath(path)
    parts = split(replace(string(path), "\", "/"), "/");
    kept = strings(0, 1);
    for k = 1:numel(parts)
        if parts(k) == "." || strlength(parts(k)) == 0
            continue;
        elseif parts(k) == ".." && ~isempty(kept) && kept(end) ~= ".."
            kept(end) = [];
        else
            kept(end + 1, 1) = parts(k);
        end
    end
    path = strjoin(kept, "/");
end

function anchor = headingAnchor(label)
    anchor = lower(regexprep(string(label), '[^A-Za-z0-9]+', '-'));
    anchor = strip(anchor, "-");
    if strlength(anchor) == 0
        anchor = "section";
    end
end

function text = htmlEscape(text)
    text = replace(string(text), "&", "&amp;");
    text = replace(text, "<", "&lt;");
    text = replace(text, ">", "&gt;");
    text = replace(text, """", "&quot;");
end
