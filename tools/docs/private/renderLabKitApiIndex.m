function [html, plainText] = renderLabKitApiIndex(model, outputPath)
%RENDERLABKITAPIINDEX Render grouped, linked API summaries for the reference home.
% Expected caller: renderLabKitDocs for the configured API landing page.
% Inputs: documentation model and current generated output path.
% Outputs: HTML fragment and searchable plain text.

    api = model.api;
    groups = apiGroups(api);
    blocks = strings(0, 1);
    words = strings(0, 1);
    for k = 1:numel(groups)
        items = api(groups(k).indices);
        rows = strings(numel(items), 1);
        for iItem = 1:numel(items)
            target = "reference/api/" + ...
                replace(string(items(iItem).symbol), ".", "/") + ".html";
            summary = cleanSummary(items(iItem).summary);
            rows(iItem) = "<tr><td><a href=""" + ...
                relativeWebPath(outputPath, target) + """><code>" + ...
                htmlEscape(items(iItem).symbol) + "</code></a></td><td>" + ...
                htmlEscape(summary) + "</td></tr>";
            words(end + 1, 1) = string(items(iItem).symbol) + " " + summary;
        end
        blocks(end + 1, 1) = "<section class=""api-group""><h2 id=""" + ...
            groups(k).id + """>" + htmlEscape(groups(k).title) + ...
            "</h2><p>" + htmlEscape(groups(k).description) + ...
            "</p><table class=""api-table""><thead><tr><th>Function</th>" + ...
            "<th>Purpose</th></tr></thead><tbody>" + strjoin(rows, "") + ...
            "</tbody></table></section>";
    end
    html = "<h2 id=""browse-by-module"">Browse By Module</h2>" + ...
        "<p>Choose a function to open its syntax, arguments, outputs, " + ...
        "behavior, source, and related APIs.</p>" + strjoin(blocks, newline);
    plainText = strjoin(words, " ");
end

function groups = apiGroups(api)
    groups = repmat(struct("id", "", "title", "", "description", "", ...
        "indices", []), 0, 1);
    symbols = string({api.symbol});
    origin = string({api.origin});
    libraryIndices = find(origin == "library");
    libraryKeys = strings(numel(libraryIndices), 1);
    for k = 1:numel(libraryIndices)
        parts = split(symbols(libraryIndices(k)), ".");
        depth = min(numel(parts) - 1, 3);
        libraryKeys(k) = strjoin(parts(1:depth), ".");
    end
    keys = unique(libraryKeys, "stable");
    for k = 1:numel(keys)
        key = keys(k);
        indices = libraryIndices(libraryKeys == key);
        groups(end + 1, 1) = struct( ...
            "id", slug(key), ...
            "title", libraryTitle(key), ...
            "description", libraryDescription(key), ...
            "indices", indices(:).');
    end

    appIndices = find(origin == "app");
    if ~isempty(appIndices)
        owners = string({api(appIndices).owner});
        ownerKeys = unique(owners, "stable");
        for k = 1:numel(ownerKeys)
            owner = ownerKeys(k);
            indices = appIndices(owners == owner);
            family = string(api(indices(1)).family);
            groups(end + 1, 1) = struct( ...
                "id", "app-" + slug(owner), ...
                "title", humanize(owner) + " App API", ...
                "description", "Supported GUI-free operations owned by the " + ...
                    humanize(owner) + " app in the " + family + " family.", ...
                "indices", indices(:).');
        end
    end
end

function title = libraryTitle(key)
    switch key
        case "labkit.contract"
            title = "Framework Compatibility (labkit.contract)";
        case "labkit.app"
            title = "App SDK Core (labkit.app)";
        case "labkit.app.diagnostic"
            title = "App SDK Diagnostics (labkit.app.diagnostic)";
        case "labkit.app.dialog"
            title = "App SDK Dialogs (labkit.app.dialog)";
        case "labkit.app.event"
            title = "App SDK Events (labkit.app.event)";
        case "labkit.app.interaction"
            title = "App SDK Interactions (labkit.app.interaction)";
        case "labkit.app.layout"
            title = "App SDK Layout (labkit.app.layout)";
        case "labkit.app.plot"
            title = "App SDK Plot Mechanics (labkit.app.plot)";
        case "labkit.app.project"
            title = "App SDK Projects (labkit.app.project)";
        case "labkit.app.result"
            title = "App SDK Results (labkit.app.result)";
        case "labkit.app.view"
            title = "App SDK Views (labkit.app.view)";
        otherwise
            title = key;
    end
end

function description = libraryDescription(key)
    switch key
        case "labkit.contract"
            description = "Version and MathWorks-product requirement contracts.";
        case "labkit.app"
            description = "App identity, launch, callback capabilities, and facade version metadata.";
        case "labkit.app.diagnostic"
            description = "Sanitized standard and verbose runtime diagnostic contracts.";
        case "labkit.app.dialog"
            description = "Typed outcomes for native user-choice and path dialogs.";
        case "labkit.app.event"
            description = "Typed semantic callback payloads independent of native controls.";
        case "labkit.app.interaction"
            description = "Managed plot gestures, editors, and typed interaction payloads.";
        case "labkit.app.layout"
            description = "Semantic controls, containers, workspaces, callbacks, and renderers.";
        case "labkit.app.plot"
            description = "Domain-neutral axes clearing, fitting, messages, and annotation mechanics.";
        case "labkit.app.project"
            description = "Durable project schemas, portable sources, and synthetic sample contracts.";
        case "labkit.app.result"
            description = "Validated result files and package manifest requests.";
        case "labkit.app.view"
            description = "Complete immutable visible-state snapshots.";
        case "labkit.image"
            description = "Generic image file IO, normalization, resizing, filtering, and enhancement primitives.";
        case "labkit.thermal"
            description = "Radiometric image inspection, conversion, reading, and rendering.";
        case "labkit.dta"
            description = "Gamry DTA discovery, parsing, curve access, and pulse detection.";
        case "labkit.rhs"
            description = "Intan RHS discovery, indexing, inspection, and bounded waveform reads.";
        case "labkit.biosignal"
            description = "Recording import, channel access, filtering, events, templates, and measurements.";
        otherwise
            description = "Public functions in " + key + ".";
    end
end

function value = cleanSummary(value)
    value = string(value);
    value = regexprep(value, '^[A-Z][A-Z0-9_]*\s+', '');
end

function value = humanize(value)
    value = replace(string(value), "_", " ");
    words = split(value);
    for k = 1:numel(words)
        if strlength(words(k)) > 0
            words(k) = upper(extractBefore(words(k), 2)) + extractAfter(words(k), 1);
        end
    end
    value = strjoin(words, " ");
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
