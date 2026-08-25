function [html, plainText] = renderLabKitMarkdown(model, page)
%RENDERLABKITMARKDOWN Render the repository's documented Markdown subset.

    lines = readlines(page.sourcePath, "EmptyLineRule", "read");
    output = strings(2 * numel(lines) + 2, 1);
    plain = strings(numel(lines), 1);
    outputCount = 0;
    plainCount = 0;
    index = 1;
    listType = "";
    inCode = false;
    codeLanguage = "";
    codeLines = strings(numel(lines), 1);
    codeLineCount = 0;
    while index <= numel(lines)
        line = lines(index);
        trimmed = strtrim(line);
        if inCode
            if startsWith(trimmed, "```")
                if ~startsWith(codeLanguage, "labkit-")
                    outputCount = outputCount + 1;
                    output(outputCount, 1) = "<pre><code class=""language-" + ...
                        htmlEscape(codeLanguage) + """>" + ...
                        htmlEscape(strjoin(codeLines(1:codeLineCount), newline)) + "</code></pre>";
                    destination = plainCount + (1:codeLineCount);
                    plain(destination, 1) = codeLines(1:codeLineCount);
                    plainCount = plainCount + codeLineCount;
                end
                inCode = false;
                codeLineCount = 0;
            else
                codeLineCount = codeLineCount + 1;
                codeLines(codeLineCount, 1) = line;
            end
            index = index + 1;
            continue;
        end
        if startsWith(trimmed, "```")
            [output, outputCount, listType] = ...
                closeList(output, outputCount, listType);
            inCode = true;
            codeLanguage = strip(extractAfter(trimmed, 3));
            index = index + 1;
            continue;
        end
        if strlength(trimmed) == 0
            [output, outputCount, listType] = ...
                closeList(output, outputCount, listType);
            index = index + 1;
            continue;
        end
        if startsWith(trimmed, "<!--") && endsWith(trimmed, "-->")
            [output, outputCount, listType] = ...
                closeList(output, outputCount, listType);
            index = index + 1;
            continue;
        end
        if isTableStart(lines, index)
            [output, outputCount, listType] = ...
                closeList(output, outputCount, listType);
            [tableHtml, tablePlain, index] = renderTable(model, page, lines, index);
            outputCount = outputCount + 1;
            output(outputCount, 1) = tableHtml;
            plainCount = plainCount + 1;
            plain(plainCount, 1) = tablePlain;
            continue;
        end
        heading = regexp(char(trimmed), '^(#{1,6})\s+(.+)$', 'tokens', 'once');
        if ~isempty(heading)
            [output, outputCount, listType] = ...
                closeList(output, outputCount, listType);
            level = strlength(string(heading{1}));
            label = string(heading{2});
            anchor = headingAnchor(label);
            outputCount = outputCount + 1;
            output(outputCount, 1) = "<h" + level + " id=""" + anchor + """>" + ...
                renderInline(model, page, label) + "</h" + level + ">";
            plainCount = plainCount + 1;
            plain(plainCount, 1) = label;
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
            itemText = string(item{1});
            index = index + 1;
            [itemText, index] = appendListItemContinuations( ...
                lines, index, itemText);
            [output, outputCount, listType] = ...
                ensureList(output, outputCount, listType, wanted);
            outputCount = outputCount + 1;
            output(outputCount, 1) = "<li>" + ...
                renderInline(model, page, itemText) + "</li>";
            plainCount = plainCount + 1;
            plain(plainCount, 1) = itemText;
            continue;
        end
        [output, outputCount, listType] = ...
            closeList(output, outputCount, listType);
        if startsWith(trimmed, ">")
            content = strip(extractAfter(trimmed, 1));
            outputCount = outputCount + 1;
            output(outputCount, 1) = "<aside class=""note"">" + ...
                renderInline(model, page, content) + "</aside>";
            plainCount = plainCount + 1;
            plain(plainCount, 1) = content;
            index = index + 1;
            continue;
        end
        if any(trimmed == ["---", "***"])
            outputCount = outputCount + 1;
            output(outputCount, 1) = "<hr>";
            index = index + 1;
            continue;
        end

        paragraph = trimmed;
        index = index + 1;
        while index <= numel(lines) && isParagraphContinuation(lines, index)
            paragraph = paragraph + " " + strtrim(lines(index));
            index = index + 1;
        end
        outputCount = outputCount + 1;
        output(outputCount, 1) = "<p>" + ...
            renderInline(model, page, paragraph) + "</p>";
        plainCount = plainCount + 1;
        plain(plainCount, 1) = paragraph;
    end
    [output, outputCount, ~] = closeList(output, outputCount, listType);
    if inCode
        error("LabKit:Docs:UnclosedCodeFence", ...
            "Page %s has an unclosed code fence.", page.source);
    end
    html = strjoin(output(1:outputCount), newline);
    plainText = strjoin(plain(1:plainCount), " ");
end

function [itemText, nextIndex] = appendListItemContinuations( ...
        lines, nextIndex, itemText)
    while nextIndex <= numel(lines)
        line = lines(nextIndex);
        trimmed = strtrim(line);
        isIndented = ~isempty(regexp(char(line), '^\s{2,}\S', 'once'));
        isListItem = ~isempty(regexp(char(line), ...
            '^\s*(?:[-*]|\d+[.])\s+', 'once'));
        if strlength(trimmed) == 0 || ~isIndented || isListItem || ...
                startsWith(trimmed, "```")
            break;
        end
        itemText = itemText + " " + trimmed;
        nextIndex = nextIndex + 1;
    end
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
    rows = cell(max(numel(lines) - index + 1, 0), 1);
    rowCount = 0;
    while index <= numel(lines) && contains(lines(index), "|") && ...
            strlength(strtrim(lines(index))) > 0
        rowCount = rowCount + 1;
        rows{rowCount, 1} = tableCells(lines(index));
        index = index + 1;
    end
    rows = rows(1:rowCount);
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

function [output, outputCount, listType] = ...
        ensureList(output, outputCount, listType, wanted)
    if listType == wanted
        return;
    end
    [output, outputCount, ~] = closeList(output, outputCount, listType);
    outputCount = outputCount + 1;
    output(outputCount, 1) = "<" + wanted + ">";
    listType = wanted;
end

function [output, outputCount, listType] = ...
        closeList(output, outputCount, listType)
    if strlength(listType) > 0
        outputCount = outputCount + 1;
        output(outputCount, 1) = "</" + listType + ">";
    end
    listType = "";
end

function html = renderInline(model, page, text)
    text = string(text);
    replacements = strings(strlength(text), 1);
    [text, replacements] = protectTokens(text, replacements, ...
        '`([^`]+)`', "code", model, page);
    [text, replacements] = protectTokens(text, replacements, ...
        '!\[([^\]]*)\]\(([^)]+)\)', "image", model, page);
    [text, replacements] = protectTokens(text, replacements, ...
        '\[([^\]]+)\]\(([^)]+)\)', "link", model, page);
    replacements = replacements(strlength(replacements) > 0);
    html = htmlEscape(text);
    html = regexprep(html, '\*\*([^*]+)\*\*', '<strong>$1</strong>');
    html = regexprep(html, '(?<!\*)\*([^*]+)\*(?!\*)', '<em>$1</em>');
    % Later replacements can contain markers created by earlier passes, as
    % with a Markdown link whose label is inline code. Restore the outermost
    % token first so nested markers are present when their turn is reached.
    for k = numel(replacements):-1:1
        html = replace(html, tokenMarker(k), replacements(k));
    end
end

function [text, replacements] = protectTokens( ...
        text, replacements, pattern, tokenType, model, page)
    replacementCount = nnz(strlength(replacements) > 0);
    while true
        [start, finish, tokens] = regexp(char(text), pattern, ...
            'start', 'end', 'tokens', 'once');
        if isempty(start)
            break;
        end
        switch tokenType
            case "code"
                replacement = "<code>" + htmlEscape(tokens{1}) + "</code>";
            case "image"
                replacement = renderImage(tokens);
            case "link"
                replacement = renderLink(model, page, tokens);
            otherwise
                error("LabKit:Docs:UnknownInlineToken", ...
                    "Unknown Markdown inline token type: %s", tokenType);
        end
        replacementCount = replacementCount + 1;
        replacements(replacementCount, 1) = replacement;
        marker = tokenMarker(replacementCount);
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
        return;
    end
    error("LabKit:Docs:UnresolvedLink", ...
        "Page %s links to an unregistered Markdown source: %s", ...
        page.source, target);
end

function path = normalizeDocPath(path)
    parts = split(replace(string(path), "\", "/"), "/");
    kept = strings(numel(parts), 1);
    keptCount = 0;
    for k = 1:numel(parts)
        if parts(k) == "." || strlength(parts(k)) == 0
            continue;
        elseif parts(k) == ".." && keptCount > 0 && kept(keptCount) ~= ".."
            keptCount = keptCount - 1;
        else
            keptCount = keptCount + 1;
            kept(keptCount, 1) = parts(k);
        end
    end
    path = strjoin(kept(1:keptCount), "/");
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
