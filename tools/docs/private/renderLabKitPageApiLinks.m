function [html, plainText] = renderLabKitPageApiLinks(model, page)
%RENDERLABKITPAGEAPILINKS Link narrative module and app pages to exact APIs.
% Expected caller: narrative-page rendering.
% Inputs: documentation model and current page record.
% Outputs: optional HTML fragment and searchable plain text.

    api = model.api;
    matches = false(numel(api), 1);
    if page.output == "framework/app-sdk-api.html"
        matches = startsWith(string({api.symbol}).', "labkit.app");
    elseif startsWith(page.id, "app-") && ~startsWith(page.id, "app-family-")
        owner = replace(extractAfter(page.id, "app-"), "-", "_");
        matches = string({api.origin}).' == "app" & ...
            string({api.owner}).' == owner;
    else
        sourceText = string(fileread(page.sourcePath));
        symbols = string({api.symbol}).';
        for k = 1:numel(symbols)
            matches(k) = contains(sourceText, symbols(k));
        end
    end
    items = api(matches);
    if isempty(items)
        html = "";
        plainText = "";
        return;
    end
    [~, order] = sort(string({items.symbol}));
    items = items(order);
    if page.output == "framework/app-sdk-api.html"
        [html, plainText] = renderAppSdkGroups(items, page.output);
        return;
    end
    rows = strings(numel(items), 1);
    words = strings(numel(items), 1);
    for k = 1:numel(items)
        target = "reference/api/" + replace(string(items(k).symbol), ".", "/") + ".html";
        summary = regexprep(string(items(k).summary), '^[A-Z][A-Z0-9_]*\s+', '');
        rows(k) = "<tr><td><a href=""" + relativeWebPath(page.output, target) + ...
            """><code>" + htmlEscape(items(k).symbol) + "</code></a></td>" + ...
            "<td>" + htmlEscape(summary) + "</td></tr>";
        words(k) = string(items(k).symbol) + " " + summary;
    end
    heading = "Functions And API";
    if page.output == "framework/app-sdk-api.html"
        heading = "Complete App SDK API";
    end
    html = "<section class=""page-api-links""><h2 id=""functions-and-api"">" + ...
        heading + "</h2><p>Open a function for exact MATLAB syntax, " + ...
        "arguments, outputs, behavior, and source.</p><table class=""api-table"">" + ...
        "<thead><tr><th>Function</th><th>Purpose</th></tr></thead><tbody>" + ...
        strjoin(rows, "") + "</tbody></table></section>";
    plainText = strjoin(words, " ");
end

function [html, plainText] = renderAppSdkGroups(items, outputPath)
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
    order = ["Core", "layout", "view", "event", "interaction", ...
        "plot", "project", "result", "dialog", "diagnostic"];
    order = order(ismember(order, groups));
    blocks = strings(numel(order), 1);
    wordChunks = cell(numel(order), 1);
    for k = 1:numel(order)
        members = items(groups == order(k));
        [tableHtml, tableWords] = apiTable(members, outputPath);
        blocks(k, 1) = "<section class=""api-group""><h3>" + ...
            htmlEscape(displayGroup(order(k))) + "</h3>" + tableHtml + "</section>";
        wordChunks{k} = tableWords;
    end
    words = strings(0, 1);
    if ~isempty(wordChunks)
        words = vertcat(wordChunks{:});
    end
    html = "<section class=""page-api-links""><h2 id=""functions-and-api"">" + ...
        "Complete App SDK API</h2><p>Open a function for exact MATLAB syntax, " + ...
        "arguments, outputs, behavior, and source.</p>" + strjoin(blocks, newline) + "</section>";
    plainText = strjoin(words, " ");
end

function [html, words] = apiTable(items, outputPath)
    rows = strings(numel(items), 1);
    words = strings(numel(items), 1);
    for k = 1:numel(items)
        target = "reference/api/" + replace(string(items(k).symbol), ".", "/") + ".html";
        summary = regexprep(string(items(k).summary), '^[A-Z][A-Z0-9_]*\s+', '');
        rows(k) = "<tr><td><a href=""" + relativeWebPath(outputPath, target) + ...
            """><code>" + htmlEscape(items(k).symbol) + "</code></a></td><td>" + ...
            htmlEscape(summary) + "</td></tr>";
        words(k) = string(items(k).symbol) + " " + summary;
    end
    html = "<table class=""api-table""><thead><tr><th>Function</th><th>Purpose</th>" + ...
        "</tr></thead><tbody>" + strjoin(rows, "") + "</tbody></table>";
end

function label = displayGroup(group)
    if group == "Core"
        label = "Core";
    else
        label = "labkit.app." + group;
    end
end

function text = htmlEscape(text)
    text = replace(string(text), "&", "&amp;");
    text = replace(text, "<", "&lt;");
    text = replace(text, ">", "&gt;");
    text = replace(text, """", "&quot;");
end
