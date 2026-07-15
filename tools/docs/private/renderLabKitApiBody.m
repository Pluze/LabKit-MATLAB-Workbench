function html = renderLabKitApiBody(model, item, outputPath)
%RENDERLABKITAPIBODY Render one source-bound MATLAB API reference page.

    indexUrl = relativeWebPath(outputPath, "reference/index.html");
    sourceUrl = model.repositoryUrl + "/blob/main/" + item.source;
    related = relatedApiItems(model.api, item.symbol);
    relatedHtml = "";
    if ~isempty(related)
        relatedHtml = "<h2 id=""related-apis"">Related APIs</h2><ul>";
        for k = 1:numel(related)
            target = "reference/api/" + replace(related(k).symbol, ".", "/") + ".html";
            relatedHtml = relatedHtml + "<li><a href=""" + ...
                relativeWebPath(outputPath, target) + """><code>" + ...
                htmlEscape(related(k).symbol) + "</code></a></li>";
        end
        relatedHtml = relatedHtml + "</ul>";
    end
    html = strjoin([ ...
        "<p><a href=""" + indexUrl + """>API Reference</a></p>"
        "<h1>" + htmlEscape(item.symbol) + "</h1>"
        "<p class=""lead"">" + htmlEscape(item.summary) + "</p>"
        "<h2 id=""syntax"">Syntax</h2>"
        "<pre><code class=""language-matlab"">" + ...
            htmlEscape(item.signature) + "</code></pre>"
        "<h2 id=""contract"">Contract</h2>"
        "<pre class=""help-contract"">" + htmlEscape(item.helpText) + "</pre>"
        "<h2 id=""source"">Source</h2>"
        "<p><a href=""" + htmlEscape(sourceUrl) + """><code>" + ...
            htmlEscape(item.source) + "</code></a></p>"
        relatedHtml], newline);
end

function related = relatedApiItems(api, symbol)
    parts = split(string(symbol), ".");
    prefix = strjoin(parts(1:max(1, numel(parts) - 1)), ".") + ".";
    symbols = string({api.symbol});
    matches = startsWith(symbols, prefix) & symbols ~= string(symbol);
    candidates = api(matches);
    related = candidates(1:min(6, numel(candidates)));
end

function text = htmlEscape(text)
    text = replace(string(text), "&", "&amp;");
    text = replace(text, "<", "&lt;");
    text = replace(text, ">", "&gt;");
    text = replace(text, """", "&quot;");
end
