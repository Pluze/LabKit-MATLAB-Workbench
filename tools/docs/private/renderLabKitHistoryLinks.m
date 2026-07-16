function [html, plainText] = renderLabKitHistoryLinks(model, page)
%RENDERLABKITHISTORYLINKS Render change records associated with a page.
% Expected caller: renderLabKitDocs narrative-page generation.
% Inputs: documentation model and current narrative page metadata.
% Outputs: deterministic HTML list and searchable plain text.
% Side effects: none. History record bodies remain separate Markdown pages.

    html = "";
    plainText = "";
    if page.kind == "history" || isempty(model.history)
        return;
    end
    history = model.history;
    if page.id ~= "history"
        if isempty(page.components)
            return;
        end
        keep = arrayfun(@(item) any(ismember(item.components, page.components)), ...
            history);
        history = history(keep);
    end
    if isempty(history)
        return;
    end

    items = strings(numel(history), 1);
    searchable = strings(numel(history), 1);
    for k = 1:numel(history)
        item = history(k);
        label = item.historyDate + " - " + item.title;
        detail = item.changeType + " | " + item.compatibility;
        items(k) = "<li><a href=""" + ...
            relativeWebPath(page.output, item.output) + """>" + ...
            htmlEscape(label) + "</a><small>" + htmlEscape(detail) + ...
            "</small></li>";
        searchable(k) = label + " " + detail + " " + ...
            strjoin(item.components, " ");
    end
    heading = "Change history";
    if page.id == "history"
        heading = "Complete timeline";
    end
    html = "<section class=""component-history""><h2>" + heading + ...
        "</h2><ul>" + ...
        strjoin(items, "") + "</ul></section>";
    plainText = strjoin(searchable, " ");
end

function text = htmlEscape(text)
    text = replace(string(text), "&", "&amp;");
    text = replace(text, "<", "&lt;");
    text = replace(text, ">", "&gt;");
    text = replace(text, """", "&quot;");
end
