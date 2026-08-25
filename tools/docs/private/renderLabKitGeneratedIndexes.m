function count = renderLabKitGeneratedIndexes(model, stagingRoot)
%RENDERLABKITGENERATEDINDEXES Build structural map and Change browse pages.

    count = 0;
    mapOutput = "map/index.html";
    mapBody = documentationMap(model, mapOutput);
    writeDocText(fullfile(stagingRoot, mapOutput), ...
        renderLabKitPage(model, "All documentation", mapOutput, ...
            "landing", mapBody));
    count = count + 1;

    components = changeComponents(model);
    componentIndex = "changes/components/index.html";
    writeDocText(fullfile(stagingRoot, componentIndex), ...
        renderLabKitPage(model, "Changes by component", componentIndex, ...
            "change index", componentIndexBody(model, components, componentIndex)));
    count = count + 1;
    for k = 1:numel(components)
        output = "changes/components/" + components(k).slug + "/index.html";
        body = componentBody(model, components(k), output);
        writeDocText(fullfile(stagingRoot, output), ...
            renderLabKitPage(model, "Changes for " + components(k).label, ...
                output, "change index", body));
        count = count + 1;
    end

    years = changeYears(model.changes);
    yearIndex = "changes/years/index.html";
    writeDocText(fullfile(stagingRoot, yearIndex), ...
        renderLabKitPage(model, "Changes by year", yearIndex, ...
            "change index", yearIndexBody(years, yearIndex)));
    count = count + 1;
    for k = 1:numel(years)
        output = "changes/years/" + years(k).year + "/index.html";
        body = yearBody(model, years(k), output);
        writeDocText(fullfile(stagingRoot, output), ...
            renderLabKitPage(model, "Changes accepted in " + years(k).year, ...
                output, "change index", body));
        count = count + 1;
    end
end

function html = documentationMap(model, outputPath)
    html = "<h1>All documentation</h1>" + ...
        "<p class=""lead"">Use this structural map when search or a task landing page is not the fastest route. It lists current guides and the generated indexes that lead to API and Change detail pages.</p>";
    html = html + mapSection(model, outputPath, "Use", "use/");
    html = html + appMap(model, outputPath);
    html = html + mapSection(model, outputPath, "Develop", "develop/");
    html = html + mapSection(model, outputPath, "Reference", "reference/");
    html = html + "<section><h2 id=""changes"">Changes</h2><ul>" + ...
        mapLink(outputPath, "changes/index.html", "Changes overview", ...
            "Start from the newest accepted changes or search by Change ID.") + ...
        mapLink(outputPath, "changes/components/index.html", ...
            "Changes by component", "Trace one App, facade, or project area.") + ...
        mapLink(outputPath, "changes/years/index.html", ...
            "Changes by year", "Browse the accepted record chronologically.") + ...
        "</ul></section>";
end

function html = mapSection(model, outputPath, title, prefix)
    pages = model.pages(startsWith(string({model.pages.output}), prefix) & ...
        string({model.pages.kind}) ~= "change");
    if string(title) == "Use"
        pages = pages(~startsWith(string({pages.output}), "use/apps/"));
    end
    if isempty(pages)
        html = "";
        return;
    end
    [~, order] = sort([pages.order]);
    pages = pages(order);
    rows = strings(numel(pages), 1);
    for k = 1:numel(pages)
        rows(k) = mapLink(outputPath, pages(k).output, pages(k).title, ...
            pages(k).summary);
    end
    html = "<section><h2 id=""" + lower(title) + """>" + ...
        escape(title) + "</h2><ul class=""map-list"">" + ...
        strjoin(rows, "") + "</ul></section>";
end

function html = appMap(model, outputPath)
    apps = model.apps;
    families = unique(string({apps.familyTitle}), "stable");
    blocks = strings(numel(families), 1);
    for k = 1:numel(families)
        members = apps(string({apps.familyTitle}) == families(k));
        [~, order] = sort(string({members.id}));
        members = members(order);
        links = strings(numel(members), 1);
        for m = 1:numel(members)
            links(m) = mapLink(outputPath, members(m).output, ...
                appTitle(model, members(m).source), members(m).description);
        end
        familyTarget = string(members(1).familySource);
        familyPage = model.pages(string({model.pages.source}) == familyTarget);
        heading = escape(families(k));
        if ~isempty(familyPage)
            heading = "<a href=""" + relativeWebPath(outputPath, ...
                string(familyPage(1).output)) + """>" + heading + "</a>";
        end
        blocks(k) = "<div class=""map-group""><h3>" + heading + ...
            "</h3><ul class=""map-list"">" + strjoin(links, "") + "</ul></div>";
    end
    html = "<section><h2 id=""app-guides"">App guides</h2><div class=""map-groups"">" + ...
        strjoin(blocks, "") + "</div></section>";
end

function title = appTitle(model, source)
    page = model.pages(string({model.pages.source}) == string(source));
    title = string(page(1).title);
end

function html = mapLink(outputPath, target, title, summary)
    html = "<li><a href=""" + relativeWebPath(outputPath, target) + ...
        """>" + escape(title) + "</a>";
    if strlength(string(summary)) > 0
        html = html + "<span>" + escape(summary) + "</span>";
    end
    html = html + "</li>";
end

function components = changeComponents(model)
    changes = model.changes;
    counts = arrayfun(@(record) numel(record.components), changes);
    ids = strings(sum(counts), 1);
    offset = 0;
    for k = 1:numel(changes)
        recordIds = labKitChangeComponentId(changes(k).components);
        ids(offset + (1:numel(recordIds))) = recordIds;
        offset = offset + numel(recordIds);
    end
    ids = unique(ids);
    template = struct("id", "", "slug", "", "label", "", ...
        "count", 0, "indices", []);
    components = repmat(template, numel(ids), 1);
    for k = 1:numel(ids)
        matches = false(numel(changes), 1);
        for m = 1:numel(changes)
            matches(m) = any(labKitChangeComponentId( ...
                changes(m).components) == ids(k));
        end
        components(k) = struct("id", ids(k), ...
            "slug", labKitChangeComponentSlug(ids(k)), ...
            "label", componentLabel(model, ids(k)), ...
            "count", nnz(matches), "indices", find(matches));
    end
    slugs = string({components.slug});
    if numel(unique(slugs)) ~= numel(slugs)
        error("LabKit:Docs:DuplicateChangeComponentRoute", ...
            "Change component identifiers produce duplicate archive routes.");
    end
    [~, order] = sort(lower(string({components.label})));
    components = components(order);
end

function html = componentIndexBody(~, components, outputPath)
    cards = strings(numel(components), 1);
    for k = 1:numel(components)
        target = "changes/components/" + components(k).slug + "/index.html";
        cards(k) = "<a class=""index-card"" href=""" + ...
            relativeWebPath(outputPath, target) + """><strong>" + ...
            escape(components(k).label) + "</strong><code>" + ...
            escape(components(k).id) + "</code><span>" + ...
            string(components(k).count) + " changes</span></a>";
    end
    html = "<h1>Changes by component</h1>" + ...
        "<p class=""lead"">Choose the App, facade, or project area whose accepted decisions you want to trace. A component archive is historical context; its current guide remains the authority for supported behavior.</p>" + ...
        "<div class=""index-grid"">" + strjoin(cards, "") + "</div>";
end

function html = componentBody(model, component, outputPath)
    records = model.changes(component.indices);
    html = "<h1>Changes for " + escape(component.label) + "</h1>" + ...
        "<p class=""lead"">Accepted changes associated with <code>" + ...
        escape(component.id) + "</code>, newest first. Follow a record to understand its reason, impact, compatibility, and links back to current documentation.</p>" + ...
        currentComponentDocumentation(model, component.id, outputPath) + ...
        changeList(model, records, outputPath, inf);
end

function html = currentComponentDocumentation(model, component, outputPath)
    matches = arrayfun(@(page) any(string(page.components) == component), ...
        model.pages);
    kinds = string({model.pages.kind}).';
    pages = model.pages(matches & kinds ~= "change");
    if isempty(pages)
        html = "";
        return;
    end
    [~, order] = sort([pages.order]);
    pages = pages(order);
    links = strings(numel(pages), 1);
    for k = 1:numel(pages)
        links(k) = "<li><a href=""" + relativeWebPath(outputPath, ...
            pages(k).output) + """>" + escape(pages(k).title) + "</a></li>";
    end
    html = "<section><h2 id=""current-documentation"">Current documentation</h2>" + ...
        "<p>Use these pages for behavior supported now.</p><ul>" + ...
        strjoin(links, "") + "</ul></section>";
end

function years = changeYears(changes)
    values = unique(extractBefore(string({changes.date}).', 5), "stable");
    values = sort(values, "descend");
    template = struct("year", "", "count", 0, "indices", []);
    years = repmat(template, numel(values), 1);
    for k = 1:numel(values)
        matches = startsWith(string({changes.date}), values(k));
        years(k) = struct("year", values(k), "count", nnz(matches), ...
            "indices", find(matches));
    end
end

function html = yearIndexBody(years, outputPath)
    cards = strings(numel(years), 1);
    for k = 1:numel(years)
        target = "changes/years/" + years(k).year + "/index.html";
        cards(k) = "<a class=""index-card"" href=""" + ...
            relativeWebPath(outputPath, target) + """><strong>" + ...
            years(k).year + "</strong><span>" + string(years(k).count) + ...
            " changes</span></a>";
    end
    html = "<h1>Changes by year</h1>" + ...
        "<p class=""lead"">Browse accepted changes chronologically. GitHub Releases summarize published versions; this archive preserves the reason and impact of individual logical changes.</p>" + ...
        "<div class=""index-grid compact"">" + strjoin(cards, "") + "</div>";
end

function html = yearBody(model, year, outputPath)
    records = model.changes(year.indices);
    months = monthNumbers(records);
    blocks = strings(numel(months), 1);
    names = ["January", "February", "March", "April", "May", "June", ...
        "July", "August", "September", "October", "November", "December"];
    for k = 1:numel(months)
        prefix = year.year + "-" + months(k);
        subset = records(startsWith(string({records.date}), prefix));
        blocks(k) = "<section><h2 id=""month-" + months(k) + """>" + ...
            names(str2double(months(k))) + "</h2>" + ...
            changeList(model, subset, outputPath, inf) + "</section>";
    end
    html = "<h1>Changes accepted in " + year.year + "</h1>" + ...
        "<p class=""lead"">The accepted logical changes for this year, grouped by month and ordered newest first.</p>" + ...
        strjoin(blocks, "");
end

function months = monthNumbers(records)
    dates = string({records.date});
    months = unique(extractBetween(dates, 6, 7));
    months = sort(months, "descend");
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
        target = relativeWebPath(outputPath, string(page(1).output));
        rows(k) = "<li><div class=""change-list-meta""><time datetime=""" + ...
            records(k).date + """>" + records(k).date + "</time><span class=""compatibility " + ...
            records(k).compatibility + """>" + displayCompatibility( ...
                records(k).compatibility) + "</span></div><a href=""" + ...
            target + """>" + escape(records(k).title) + "</a><code>" + ...
            records(k).id + "</code></li>";
    end
    html = "<ol class=""change-list"">" + strjoin(rows, "") + "</ol>";
end

function label = displayCompatibility(value)
    label = replace(string(value), "-", " ");
    label = upper(extractBefore(label, 2)) + extractAfter(label, 1);
end

function label = componentLabel(model, id)
    id = string(id);
    app = model.apps(string({model.apps.command}) == id);
    if ~isempty(app)
        label = appTitle(model, app(1).source);
    elseif startsWith(id, "labkit_") && endsWith(id, "_app")
        name = erase(extractBetween(id, 8, strlength(id) - 4), "_");
        label = splitCamelCase(name);
    elseif id == "labkit_launcher"
        label = "LabKit Launcher";
    elseif id == "documentation"
        label = "Documentation";
    elseif id == "repository"
        label = "Repository and delivery";
    elseif id == "labkit-project"
        label = "App project contracts";
    elseif id == "labkit.ui"
        label = "Retired labkit.ui framework";
    else
        label = id;
    end
end

function value = splitCamelCase(value)
    value = regexprep(string(value), '([a-z0-9])([A-Z])', '$1 $2');
end

function value = escape(value)
    value = replace(string(value), "&", "&amp;");
    value = replace(value, "<", "&lt;");
    value = replace(value, ">", "&gt;");
    value = replace(value, """", "&quot;");
end
