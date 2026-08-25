function [html, plainText] = renderLabKitChangeLinks(model, page)
%RENDERLABKITCHANGELINKS Render Change facts and reason relationships.

    records = model.changes;
    source = string(page.source);
    recordIndex = find(string({records.source}) == source, 1);
    links = strings(0, 1);
    facts = "";
    if ~isempty(recordIndex)
        record = records(recordIndex);
        facts = recordFacts(record);
        links = recordLinks(model, record, page.output);
    elseif ~isempty(page.components)
        links = componentChangeLinks(model, page.components, page.output);
    end
    if isempty(links) && strlength(facts) == 0
        html = "";
        plainText = "";
        return;
    end
    relations = "";
    if ~isempty(links)
        relations = "<section class=""change-links""><h2 id=""related-changes"">" + ...
            "Related changes</h2><ul>" + strjoin(links, "") + "</ul></section>";
    end
    html = facts + relations;
    plainText = "";
end

function html = recordFacts(record)
    rows = strings(0, 1);
    rows(end + 1, 1) = fact("Change ID", "<code>" + escape(record.id) + "</code>");
    rows(end + 1, 1) = fact("Accepted", escape(record.date));
    rows(end + 1, 1) = fact("Type", escape(record.changeType));
    rows(end + 1, 1) = fact("Compatibility", escape(record.compatibility));
    rows(end + 1, 1) = fact("Components", ...
        strjoin("<code>" + escape(record.components) + "</code>", "<br>"));
    html = "<dl class=""record-facts"">" + strjoin(rows, "") + "</dl>";
end

function html = fact(label, value)
    html = "<div><dt>" + escape(label) + "</dt><dd>" + value + "</dd></div>";
end

function links = recordLinks(model, record, currentOutput)
    links = strings(0, 1);
    links = appendTargets(links, model, record.supersedes, currentOutput, ...
        "Supersedes change");
    changes = model.changes;
    for change = changes.'
        if any(change.supersedes == record.id)
            links = appendTarget(links, model, change.id, currentOutput, ...
                "Superseded by change");
        end
    end
end

function links = componentChangeLinks(model, components, currentOutput)
    links = strings(0, 1);
    changes = model.changes;
    matched = false(numel(changes), 1);
    for k = 1:numel(changes)
        ids = componentIds(changes(k).components);
        matched(k) = any(ismember(ids, components));
    end
    changes = changes(matched);
    if isempty(changes)
        return;
    end
    [~, order] = sort(string({changes.date}), "descend");
    changes = changes(order);
    for k = 1:min(5, numel(changes))
        links = appendTarget(links, model, changes(k).id, currentOutput, "Change");
    end
end

function ids = componentIds(values)
    ids = strings(numel(values), 1);
    for k = 1:numel(values)
        ids(k) = strip(extractBefore(values(k) + " |", " |"));
    end
end

function links = appendTargets(links, model, ids, currentOutput, label)
    for id = ids.'
        links = appendTarget(links, model, id, currentOutput, label);
    end
end

function links = appendTarget(links, model, id, currentOutput, label)
    records = model.changes;
    recordIndex = find(string({records.id}) == id, 1);
    if isempty(recordIndex)
        return;
    end
    pages = model.pages;
    pageIndex = find(string({pages.source}) == records(recordIndex).source, 1);
    if isempty(pageIndex)
        return;
    end
    target = relativeWebPath(currentOutput, string(pages(pageIndex).output));
    title = string(records(recordIndex).title);
    links(end + 1, 1) = "<li><span>" + escape(label) + ...
        ":</span> <a href=""" + escape(target) + """>" + ...
        "<code>" + escape(id) + "</code> " + escape(title) + ...
        "</a></li>";
end

function value = escape(value)
    value = replace(string(value), "&", "&amp;");
    value = replace(value, "<", "&lt;");
    value = replace(value, ">", "&gt;");
    value = replace(value, """", "&quot;");
end
