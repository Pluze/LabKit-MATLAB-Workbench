function [beforeBody, afterBody, plainText] = renderLabKitChangeContent(model, page)
%RENDERLABKITCHANGECONTENT Add accepted-change context to rendered pages.
% Expected caller: renderLabKitDocs for narrative and public API pages.
% Inputs: validated documentation model and current page record.
% Outputs: fragments before and after authored content plus searchable text.

    beforeBody = "";
    afterBody = "";
    plainText = "";
    if isfield(page, "id") && page.id == "changes"
        [overview, plainText] = changesOverview(model, page.output);
        afterBody = afterBody + overview;
    end

    records = model.changes;
    recordIndex = find(string({records.source}) == string(page.source), 1);
    if ~isempty(recordIndex)
        record = records(recordIndex);
        beforeBody = recordFacts(record, page.output);
        afterBody = afterBody + recordRelationships(model, record, page.output);
        return;
    end
    if isempty(page.components)
        return;
    end
    links = componentChangeLinks(model, page.components, page.output);
    archives = componentArchiveLinks(model, page.components, page.output);
    if isempty(links) && isempty(archives)
        return;
    end
    afterBody = afterBody + ...
        "<section class=""change-links""><h2 id=""related-changes"">" + ...
        "Related changes</h2><p>Use the current page for supported behavior; " + ...
        "open a Change when you need the reason, impact, or compatibility " + ...
        "of an accepted change.</p><ul>" + ...
        strjoin([links; archives], "") + "</ul></section>";
end

function [html, plainText] = changesOverview(model, outputPath)
    changes = model.changes;
    components = unique(labKitChangeComponentId( ...
        vertcat(changes.components)), "stable");
    years = unique(extractBefore(string({changes.date}), 5));
    sensitive = changes(ismember(string({changes.compatibility}), ...
        ["breaking", "action-required"]));
    html = "<section class=""change-browse""><h2 id=""browse-changes"">" + ...
        "Browse changes</h2><div class=""index-grid compact"">" + ...
        browseCard(outputPath, "changes/components/index.html", ...
            "By component", string(numel(components)) + ...
            " App, facade, and project areas") + ...
        browseCard(outputPath, "changes/years/index.html", ...
            "By year", string(numel(years)) + " chronological archives") + ...
        "</div></section><section><h2 id=""latest-changes"">" + ...
        "Latest accepted changes</h2>" + ...
        changeList(model, changes, outputPath, 12) + ...
        "</section><section><h2 id=""compatibility-sensitive"">" + ...
        "Compatibility-sensitive changes</h2>" + ...
        "<p>These records were marked breaking or action-required when " + ...
        "accepted. Read the current guide and published Release before " + ...
        "acting on an older record.</p>" + ...
        changeList(model, sensitive, outputPath, 8) + "</section>";
    plainText = "Browse changes by component or year. Latest accepted " + ...
        "changes and compatibility-sensitive changes.";
end

function html = browseCard(outputPath, target, title, description)
    html = "<a class=""index-card"" href=""" + ...
        relativeWebPath(outputPath, target) + """><strong>" + ...
        escapeLabKitHtml(title) + "</strong><span>" + escapeLabKitHtml(description) + "</span></a>";
end

function html = changeList(model, records, outputPath, limit)
    if isempty(records)
        html = "<p>No accepted changes match this view.</p>";
        return;
    end
    keys = string({records.date}) + " " + string({records.id});
    [~, order] = sort(keys, "descend");
    records = records(order);
    records = records(1:min(numel(records), limit));
    rows = strings(numel(records), 1);
    for k = 1:numel(records)
        page = model.pages(string({model.pages.source}) == records(k).source);
        rows(k) = "<li><div class=""change-list-meta""><time datetime=""" + ...
            records(k).date + """>" + records(k).date + ...
            "</time><span class=""compatibility " + ...
            records(k).compatibility + """>" + ...
            displayCompatibility(records(k).compatibility) + ...
            "</span></div><a href=""" + ...
            relativeWebPath(outputPath, string(page(1).output)) + """>" + ...
            escapeLabKitHtml(records(k).title) + "</a><code>" + records(k).id + ...
            "</code></li>";
    end
    html = "<ol class=""change-list"">" + strjoin(rows, "") + "</ol>";
end

function html = recordFacts(record, currentOutput)
    rows = strings(0, 1);
    rows(end + 1) = fact("Change ID", ...
        "<code>" + escapeLabKitHtml(record.id) + "</code>");
    rows(end + 1) = fact("Accepted", ...
        "<time datetime=""" + escapeLabKitHtml(record.date) + """>" + ...
        escapeLabKitHtml(record.date) + "</time>");
    rows(end + 1) = fact("Type", escapeLabKitHtml(record.changeType));
    rows(end + 1) = fact("Compatibility", ...
        "<span class=""compatibility " + escapeLabKitHtml(record.compatibility) + ...
        """>" + escapeLabKitHtml(replace(record.compatibility, "-", " ")) + "</span>");
    values = strings(numel(record.components), 1);
    for k = 1:numel(record.components)
        id = labKitChangeComponentId(record.components(k));
        archive = "changes/components/" + ...
            labKitChangeComponentSlug(id) + "/index.html";
        transition = "";
        if contains(record.components(k), " | ")
            transition = strip(extractAfter(record.components(k), " | "));
        end
        values(k) = "<span class=""component-fact""><a href=""" + ...
            relativeWebPath(currentOutput, archive) + """><code>" + ...
            escapeLabKitHtml(id) + "</code></a>";
        if strlength(transition) > 0
            values(k) = values(k) + ...
                " <span class=""component-transition"">" + ...
                escapeLabKitHtml(transition) + "</span>";
        end
        values(k) = values(k) + "</span>";
    end
    rows(end + 1) = fact("Components", ...
        "<span class=""component-facts"">" + ...
        strjoin(values, "") + "</span>");
    html = "<dl class=""record-facts"">" + strjoin(rows, "") + "</dl>";
end

function html = fact(label, value)
    html = "<div><dt>" + escapeLabKitHtml(label) + ...
        "</dt><dd>" + value + "</dd></div>";
end

function html = recordRelationships(model, record, currentOutput)
    current = currentDocumentationLinks(model, record, currentOutput);
    decisions = decisionLinks(model, record, currentOutput);
    sections = strings(0, 1);
    if ~isempty(current)
        sections(end + 1) = "<section class=""change-links"">" + ...
            "<h2 id=""affected-current-documentation"">" + ...
            "Affected current documentation</h2><p>These pages describe " + ...
            "the behavior supported now. This Change preserves why the " + ...
            "accepted result differs from its earlier baseline.</p><ul>" + ...
            strjoin(current, "") + "</ul></section>";
    end
    if ~isempty(decisions)
        sections(end + 1) = "<section class=""change-links"">" + ...
            "<h2 id=""decision-chain"">Decision chain</h2><ul>" + ...
            strjoin(decisions, "") + "</ul></section>";
    end
    html = strjoin(sections, "");
end

function links = currentDocumentationLinks(model, record, currentOutput)
    components = labKitChangeComponentId(record.components);
    pages = model.pages;
    matched = false(numel(pages), 1);
    for k = 1:numel(pages)
        matched(k) = string(pages(k).kind) ~= "change" && ...
            any(ismember(string(pages(k).components), components));
    end
    pages = pages(matched);
    if isempty(pages)
        links = strings(0, 1);
        return;
    end
    [~, order] = sort([pages.order]);
    pages = pages(order);
    links = strings(min(8, numel(pages)), 1);
    for k = 1:numel(links)
        links(k) = "<li><a href=""" + relativeWebPath(currentOutput, ...
            pages(k).output) + """>" + escapeLabKitHtml(pages(k).title) + ...
            "</a><span>Current " + escapeLabKitHtml(pages(k).type) + "</span></li>";
    end
end

function links = decisionLinks(model, record, currentOutput)
    links = strings(0, 1);
    links = appendTargets(links, model, record.supersedes, currentOutput, ...
        "Supersedes");
    for change = model.changes.'
        if any(change.supersedes == record.id)
            links = appendTarget(links, model, change.id, currentOutput, ...
                "Superseded by");
        end
    end
end

function links = componentChangeLinks(model, components, currentOutput)
    ids = string(components);
    changes = model.changes;
    matched = false(numel(changes), 1);
    for k = 1:numel(changes)
        matched(k) = any(ismember( ...
            labKitChangeComponentId(changes(k).components), ids));
    end
    changes = changes(matched);
    if isempty(changes)
        links = strings(0, 1);
        return;
    end
    keys = string({changes.date}) + " " + string({changes.id});
    [~, order] = sort(keys, "descend");
    changes = changes(order);
    links = strings(min(5, numel(changes)), 1);
    for k = 1:numel(links)
        links(k) = changeTarget(model, changes(k).id, ...
            currentOutput, "Change");
    end
end

function links = componentArchiveLinks(model, components, currentOutput)
    counts = arrayfun(@(change) numel(change.components), model.changes);
    recorded = strings(sum(counts), 1);
    offset = 0;
    for k = 1:numel(model.changes)
        ids = labKitChangeComponentId(model.changes(k).components);
        recorded(offset + (1:numel(ids))) = ids;
        offset = offset + numel(ids);
    end
    components = intersect(unique(string(components), "stable"), ...
        unique(recorded, "stable"), "stable");
    links = strings(numel(components), 1);
    for k = 1:numel(components)
        target = "changes/components/" + ...
            labKitChangeComponentSlug(components(k)) + "/index.html";
        links(k) = "<li><a href=""" + ...
            relativeWebPath(currentOutput, target) + ...
            """>All changes for <code>" + escapeLabKitHtml(components(k)) + ...
            "</code></a></li>";
    end
end

function links = appendTargets(links, model, ids, currentOutput, label)
    additions = strings(numel(ids), 1);
    for k = 1:numel(ids)
        additions(k) = changeTarget(model, ids(k), currentOutput, label);
    end
    links = [links; additions];
end

function links = appendTarget(links, model, id, currentOutput, label)
    links(end + 1) = changeTarget(model, id, currentOutput, label);
end

function html = changeTarget(model, id, currentOutput, label)
    records = model.changes;
    recordIndex = find(string({records.id}) == id, 1);
    pages = model.pages;
    pageIndex = find(string({pages.source}) == records(recordIndex).source, 1);
    target = relativeWebPath(currentOutput, string(pages(pageIndex).output));
    html = "<li><span>" + escapeLabKitHtml(label) + ":</span> <a href=""" + ...
        escapeLabKitHtml(target) + """><code>" + escapeLabKitHtml(id) + "</code> " + ...
        escapeLabKitHtml(records(recordIndex).title) + "</a></li>";
end

function label = displayCompatibility(value)
    label = replace(string(value), "-", " ");
    label = upper(extractBefore(label, 2)) + extractAfter(label, 1);
end
