function [html, plainText] = renderLabKitPageApiLinks(model, page)
%RENDERLABKITPAGEAPILINKS Link narrative module and app pages to exact APIs.
% Expected caller: narrative-page rendering.
% Inputs: documentation model and current page record.
% Outputs: optional HTML fragment and searchable plain text.

    api = model.api;
    matches = false(numel(api), 1);
    if startsWith(page.id, "app-") && ~startsWith(page.id, "app-family-")
        owner = replace(extractAfter(page.id, "app-"), "-", "_");
        matches = string({api.origin}).' == "app" & ...
            string({api.owner}).' == owner;
    elseif ~isempty(page.components)
        components = string(page.components(:));
        symbols = string({api.symbol}).';
        for k = 1:numel(components)
            component = components(k);
            if startsWith(component, "labkit.")
                matches = matches | symbols == component | ...
                    startsWith(symbols, component + ".");
            end
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
    html = "<section class=""page-api-links""><h2 id=""functions-and-api"">" + ...
        "Functions And API</h2><p>Open a function for exact MATLAB syntax, " + ...
        "arguments, outputs, behavior, and source.</p><table class=""api-table"">" + ...
        "<thead><tr><th>Function</th><th>Purpose</th></tr></thead><tbody>" + ...
        strjoin(rows, "") + "</tbody></table></section>";
    plainText = strjoin(words, " ");
end

function text = htmlEscape(text)
    text = replace(string(text), "&", "&amp;");
    text = replace(text, "<", "&lt;");
    text = replace(text, ">", "&gt;");
    text = replace(text, """", "&quot;");
end
