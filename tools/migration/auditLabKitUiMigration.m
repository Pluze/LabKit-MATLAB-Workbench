function report = auditLabKitUiMigration(repoRoot, options)
%AUDITLABKITUIMIGRATION Inventory the current App-facing UI contract.
%
% Usage:
%   report = auditLabKitUiMigration
%   report = auditLabKitUiMigration(repoRoot)
%   report = auditLabKitUiMigration(repoRoot, Write=true)
%
% Description:
%   Builds deterministic Phase-0 evidence for the UI explicit-contract
%   redesign. The report inventories public labkit.ui functions, current App
%   definition/layout/presentation/interaction/service patterns, callback
%   signatures, framework-consumed shadow-contract fields, and
%   version-bearing repository paths. With Write=true it also writes the
%   machine-readable baseline and a compact capability matrix.
%
% Inputs:
%   repoRoot - LabKit repository root. Default: repository containing this
%       function.
%
% Name-Value Arguments:
%   Write - Logical scalar. Write baseline.json and capability-matrix.md under
%       OutputRoot. Default: false.
%   OutputRoot - Evidence folder. Default:
%       .agents/migration/ui-explicit-contract beneath repoRoot.
%
% Outputs:
%   report - Scalar structure with apps, matches, frameworkMatches,
%       publicUiSymbols, versionNamedPaths, and summary fields.
%
% Errors:
%   LabKit:Migration:InvalidRoot - repoRoot is not a LabKit checkout.
%   LabKit:Migration:WriteFailed - An evidence file cannot be written.
%
% Side effects:
%   Write=true creates or updates deterministic migration evidence files.
%
% Example:
%   report = auditLabKitUiMigration(pwd);
%   assert(report.summary.appCount == 21);
%
% See also labkit_launcher

    arguments
        repoRoot (1, 1) string = defaultRepositoryRoot()
        options.Write (1, 1) logical = false
        options.OutputRoot (1, 1) string = ""
    end
    repoRoot = absoluteRepositoryRoot(repoRoot);
    if strlength(options.OutputRoot) == 0
        options.OutputRoot = fullfile(repoRoot, ".agents", "migration", ...
            "ui-explicit-contract");
    end

    apps = discoveredApps(repoRoot);
    matches = scanApps(repoRoot, apps);
    appEvidence = summarizeApps(repoRoot, apps, matches);
    callPatterns = classifyCallPatterns(matches);
    publicSymbols = discoverPublicUiSymbols(repoRoot);
    frameworkMatches = scanFrameworkContracts(repoRoot);
    versionPaths = discoverVersionNamedPaths(repoRoot);
    report = struct( ...
        "schemaVersion", 2, ...
        "debtId", "ui-explicit-contract-redesign", ...
        "publicUiSymbols", publicSymbols, ...
        "apps", appEvidence, ...
        "matches", matches, ...
        "callPatternClassifications", callPatterns, ...
        "frameworkMatches", frameworkMatches, ...
        "versionNamedPaths", versionPaths, ...
        "summary", reportSummary(appEvidence, matches, ...
            frameworkMatches, publicSymbols, versionPaths));

    if options.Write
        writeEvidence(options.OutputRoot, report);
    end
end

function patterns = classifyCallPatterns(matches)
    if isempty(matches)
        patterns = repmat(emptyCallPattern(), 0, 1);
        return;
    end
    keys = unique(string({matches.category}).' + "|" + ...
        string({matches.value}).');
    patterns = repmat(emptyCallPattern(), numel(keys), 1);
    for k = 1:numel(keys)
        parts = split(keys(k), "|");
        category = parts(1);
        value = strjoin(parts(2:end), "|");
        selected = string({matches.category}) == category & ...
            string({matches.value}) == value;
        [disposition, owner, rationale, testStrategy] = ...
            callPatternPolicy(category, value);
        patterns(k) = struct( ...
            "category", char(category), ...
            "value", char(value), ...
            "appCount", numel(unique(string({matches(selected).appId}))), ...
            "occurrenceCount", nnz(selected), ...
            "disposition", char(disposition), ...
            "owner", char(owner), ...
            "rationale", char(rationale), ...
            "testStrategy", char(testStrategy));
    end
end

function [disposition, owner, rationale, testStrategy] = ...
        callPatternPolicy(category, value)
    owner = "labkit.ui";
    testStrategy = "strict constructor/compiler contract test";
    switch category
        case "layout-constructor"
            disposition = "replace";
            rationale = ...
                "Retain the semantic UI concept through a strict explicit constructor.";
        case "definition-field"
            disposition = "replace";
            rationale = ...
                "Replace the open definition struct field with an explicit product contract.";
        case "presentation-transport"
            disposition = "replace";
            rationale = ...
                "Replace raw view transport structs with target-checked operations.";
            testStrategy = "GUI-free presentation compilation and transaction test";
        case "interaction-kind"
            disposition = "replace";
            rationale = ...
                "Replace string Kind dispatch and Options bags with named interactions.";
            testStrategy = "interaction constructor, lifecycle, and GUI gesture test";
        case "service-call"
            if any(startsWith(value, ["figure", "debug", "request"]))
                disposition = "remove";
                rationale = ...
                    "Do not expose concrete UI, debug, or launch-request internals.";
            else
                disposition = "replace";
                rationale = ...
                    "Retain the capability behind one documented runtime context.";
            end
            testStrategy = "runtime-context interface and test-double parity test";
        case "event-meta"
            disposition = "replace";
            rationale = ...
                "Replace generic event decoding with role-specific typed payloads.";
            testStrategy = "signal signature and payload contract test";
        case "registry-access"
            disposition = "remove";
            rationale = ...
                "Apps must not read registries, figures, or component handles.";
            testStrategy = "static App boundary guardrail";
        case "callback-signature"
            disposition = "replace";
            rationale = ...
                "Declare and validate callback roles before launch.";
            testStrategy = "callback-role compilation test";
        otherwise
            disposition = "unclassified";
            owner = "architecture-review";
            rationale = "Requires Phase 1 ownership decision.";
            testStrategy = "RFC decision evidence";
    end
end

function item = emptyCallPattern()
    item = struct("category", "", "value", "", "appCount", 0, ...
        "occurrenceCount", 0, "disposition", "", "owner", "", ...
        "rationale", "", "testStrategy", "");
end

function root = defaultRepositoryRoot()
    root = string(fileparts(fileparts(fileparts(mfilename("fullpath")))));
end

function root = absoluteRepositoryRoot(root)
    [ok, attributes] = fileattrib(root);
    if ~ok || ~attributes.directory || ...
            ~isfile(fullfile(attributes.Name, "labkit_launcher.m"))
        error("LabKit:Migration:InvalidRoot", ...
            "Not a LabKit repository root: %s", root);
    end
    root = string(attributes.Name);
end

function apps = discoveredApps(repoRoot)
    oldPath = path;
    cleanup = onCleanup(@() path(oldPath));
    addpath(repoRoot, "-begin");
    catalog = labkit_launcher("list");
    clear cleanup
    catalog = catalog(catalog.Visibility == "public", :);
    [~, order] = sort(catalog.Command);
    catalog = catalog(order, :);
    template = struct("id", "", "command", "", "title", "", ...
        "family", "", "folder", "");
    apps = repmat(template, height(catalog), 1);
    for k = 1:height(catalog)
        [~, folderName] = fileparts(catalog.Folder(k));
        apps(k) = struct( ...
            "id", char(replace(string(folderName), "_", "-")), ...
            "command", char(catalog.Command(k)), ...
            "title", char(catalog.DisplayName(k)), ...
            "family", char(catalog.Family(k)), ...
            "folder", char(normalizedRelativePath( ...
                repoRoot, catalog.Folder(k))));
    end
end

function matches = scanApps(repoRoot, apps)
    matches = repmat(emptyMatch(), 0, 1);
    for k = 1:numel(apps)
        root = fullfile(repoRoot, apps(k).folder);
        entries = dir(fullfile(root, "**", "*.m"));
        for iFile = 1:numel(entries)
            filepath = string(fullfile(entries(iFile).folder, ...
                entries(iFile).name));
            lines = readlines(filepath, "EmptyLineRule", "read");
            source = normalizedRelativePath(repoRoot, filepath);
            for iLine = 1:numel(lines)
                matches = appendLineMatches(matches, apps(k).id, ...
                    source, iLine, lines(iLine));
            end
        end
    end
    if ~isempty(matches)
        keys = string({matches.appId}).' + "|" + ...
            string({matches.category}).' + "|" + ...
            string({matches.source}).' + "|" + ...
            compose("%08d", [matches.line].') + "|" + ...
            string({matches.value}).';
        [~, order] = sort(keys);
        matches = matches(order);
    end
end

function matches = appendLineMatches(matches, appId, source, lineNumber, line)
    if startsWith(strip(line), "%")
        return;
    end
    specs = patternSpecs();
    tokenSets = cell(numel(specs), 1);
    matchCount = 0;
    for k = 1:numel(specs)
        if ~patternApplies(specs(k).category, source)
            continue;
        end
        tokenSets{k} = regexp(char(line), specs(k).pattern, "tokens");
        matchCount = matchCount + numel(tokenSets{k});
    end
    found = repmat(emptyMatch(), matchCount, 1);
    cursor = 0;
    for k = 1:numel(specs)
        tokens = tokenSets{k};
        for iToken = 1:numel(tokens)
            cursor = cursor + 1;
            value = strjoin(string(tokens{iToken}), ".");
            found(cursor) = struct( ...
                "appId", char(appId), ...
                "category", char(specs(k).category), ...
                "value", char(value), ...
                "source", char(source), ...
                "line", double(lineNumber));
        end
    end
    matches = [matches; found];
end

function tf = patternApplies(category, source)
    source = string(source);
    switch string(category)
        case "definition-field"
            tf = endsWith(source, "/definition.m");
        case {"presentation-transport", "interaction-kind"}
            tf = endsWith(source, "/+userInterface/presentWorkbench.m");
        case "callback-signature"
            tf = endsWith(source, [ ...
                "/definition.m"
                "/definitionActions.m"
                "/projectSpec.m"
                "/createSession.m"]);
        otherwise
            tf = true;
    end
end

function specs = patternSpecs()
    specs = [ ...
        patternSpec("layout-constructor", ...
            'labkit[.]ui[.]layout[.]([A-Za-z][A-Za-z0-9_]*)')
        patternSpec("definition-field", ...
            '["'']([A-Z][A-Za-z0-9_]*)["'']\s*,')
        patternSpec("presentation-transport", ...
            'view[.](controls|previews|interactions)')
        patternSpec("interaction-kind", ...
            '["'']Kind["'']\s*,\s*["'']([^"'']+)["'']')
        patternSpec("service-call", ...
            'services[.]([A-Za-z][A-Za-z0-9_]*)(?:[.]([A-Za-z][A-Za-z0-9_]*))?')
        patternSpec("event-meta", ...
            'event[.]meta(?:[.]([A-Za-z][A-Za-z0-9_]*))?')
        patternSpec("registry-access", ...
            '(services[.]figure|registry|componentHandles)')
        patternSpec("callback-signature", ...
            '^\s*function\s+(?:\[[^\]]*\]|[^=]+)?=?\s*([A-Za-z][A-Za-z0-9_]*)\s*\(([^)]*)\)')];
end

function spec = patternSpec(category, pattern)
    spec = struct("category", category, "pattern", pattern);
end

function item = emptyMatch()
    item = struct("appId", "", "category", "", "value", "", ...
        "source", "", "line", 0);
end

function evidence = summarizeApps(repoRoot, apps, matches)
    categories = string({patternSpecs().category});
    template = struct("id", "", "command", "", "title", "", ...
        "family", "", "folder", "", "fileCount", 0, ...
        "categories", struct());
    evidence = repmat(template, numel(apps), 1);
    for k = 1:numel(apps)
        appMatches = matches(string({matches.appId}) == string(apps(k).id));
        categorySummary = struct();
        for iCategory = 1:numel(categories)
            field = matlab.lang.makeValidName(categories(iCategory), ...
                "ReplacementStyle", "delete");
            selected = appMatches(string({appMatches.category}) == ...
                categories(iCategory));
            categorySummary.(field) = struct( ...
                "count", numel(selected), ...
                "values", unique(string({selected.value}), "stable"));
        end
        files = dir(fullfile(repoRoot, apps(k).folder, "**", "*.m"));
        evidence(k) = struct( ...
            "id", apps(k).id, ...
            "command", apps(k).command, ...
            "title", apps(k).title, ...
            "family", apps(k).family, ...
            "folder", apps(k).folder, ...
            "fileCount", numel(files), ...
            "categories", categorySummary);
    end
end

function symbols = discoverPublicUiSymbols(repoRoot)
    root = fullfile(repoRoot, "+labkit", "+ui");
    entries = dir(fullfile(root, "**", "*.m"));
    symbols = strings(numel(entries), 1);
    cursor = 0;
    for k = 1:numel(entries)
        filepath = string(fullfile(entries(k).folder, entries(k).name));
        relative = replace(extractAfter(filepath, ...
            string(fullfile(repoRoot, "+labkit")) + filesep), filesep, "/");
        if contains("/" + relative + "/", "/private/")
            continue;
        end
        parts = split(relative, "/");
        packages = erase(parts(startsWith(parts, "+")), "+");
        [~, name] = fileparts(parts(end));
        cursor = cursor + 1;
        symbols(cursor) = strjoin(["labkit"; packages; name], ".");
    end
    symbols = symbols(1:cursor);
    symbols = sort(unique(symbols));
end

function matches = scanFrameworkContracts(repoRoot)
    specs = frameworkPatternSpecs();
    chunks = cell(numel(specs), 1);
    for k = 1:numel(specs)
        lines = readlines(fullfile(repoRoot, specs(k).source), ...
            "EmptyLineRule", "read");
        tokenSets = regexp(cellstr(lines), specs(k).pattern, "tokens");
        commentLines = startsWith(strip(lines), "%");
        tokenSets(commentLines) = {{}};
        count = sum(cellfun(@numel, tokenSets));
        chunk = repmat(emptyFrameworkMatch(), count, 1);
        cursor = 0;
        for iLine = 1:numel(lines)
            tokens = tokenSets{iLine};
            for iToken = 1:numel(tokens)
                values = string(tokens{iToken});
                values = values(strlength(values) > 0);
                if isempty(values)
                    continue;
                end
                cursor = cursor + 1;
                chunk(cursor) = struct( ...
                    "category", char(specs(k).category), ...
                    "value", char(strjoin(values, ".")), ...
                    "source", char(specs(k).source), ...
                    "line", double(iLine));
            end
        end
        chunks{k} = chunk(1:cursor);
    end
    matches = vertcat(chunks{:});
    if isempty(matches)
        return;
    end
    keys = string({matches.category}).' + "|" + ...
        string({matches.value}).' + "|" + string({matches.source}).' + ...
        "|" + compose("%08d", [matches.line].');
    [~, order] = sort(keys);
    matches = matches(order);
end

function specs = frameworkPatternSpecs()
    definition = "+labkit/+ui/+runtime/private/validateAppDefinition.m";
    layout = "+labkit/+ui/+runtime/private/validateWorkbenchLayout.m";
    prepare = "+labkit/+ui/+runtime/private/prepareV2Layout.m";
    presentation = "+labkit/+ui/+runtime/private/commitV2Presentation.m";
    interaction = ...
        "+labkit/+ui/+runtime/private/reconcileV2Interactions.m";
    services = "+labkit/+ui/+runtime/private/buildV2RuntimeServices.m";
    event = "+labkit/+ui/+runtime/private/semanticEvent.m";
    resources = "+labkit/+ui/+runtime/private/v2ResourceRegistry.m";
    result = "+labkit/+ui/+runtime/private/writeV2ResultManifest.m";
    state = "+labkit/+ui/+runtime/private/createV2State.m";
    stateValidation = "+labkit/+ui/+runtime/private/validateV2State.m";
    specs = [ ...
        frameworkPattern("definition-field", definition, ...
            'def[.]([A-Za-z][A-Za-z0-9_]*)')
        frameworkPattern("project-field", definition, ...
            'spec[.]([A-Z][A-Za-z0-9_]*)')
        frameworkPattern("project-field", definition, ...
            'isfield[(]spec,\s*[''"]([A-Z][A-Za-z0-9_]*)[''"][)]')
        frameworkPattern("layout-field", layout, ...
            '(?:layout|node)[.]([A-Za-z][A-Za-z0-9_]*)')
        frameworkPattern("layout-field", layout, ...
            'isfield[(](?:layout|node)[.]props,\s*[''"]([^''"]+)[''"][)]')
        frameworkPattern("layout-binding-field", prepare, ...
            'propertyValue[(]node[.]props,\s*["'']([^"'']+)["''][)]')
        frameworkPattern("presentation-root", presentation, ...
            'isfield[(]presentation,\s*[''"]([^''"]+)[''"][)]')
        frameworkPattern("control-presentation-field", presentation, ...
            'propertyValue[(]spec,\s*["'']([^"'']+)["''][)]')
        frameworkPattern("preview-field", presentation, ...
            'propertyValue[(]spec,\s*["''](Axes|Renderer|Model)["''][)]')
        frameworkPattern("interaction-field", interaction, ...
            'spec[.]([A-Z][A-Za-z0-9_]*)')
        frameworkPattern("interaction-field", interaction, ...
            '(?:requiredValue|optionValue)[(](?:value|spec)[^,]*,\s*[''"]([^''"]+)[''"]')
        frameworkPattern("service-group", services, ...
            'services[.]([a-z][A-Za-z0-9_]*)')
        frameworkPattern("service-operation", services, ...
            '^\s*["'']([A-Za-z][A-Za-z0-9_]*)["'']\s*,\s*@')
        frameworkPattern("event-field", event, ...
            'event[.]([a-z][A-Za-z0-9_]*)')
        frameworkPattern("resource-field", resources, ...
            'entry[.]([a-z][A-Za-z0-9_]*)')
        frameworkPattern("result-field", result, ...
            '^\s*["'']([A-Za-z][A-Za-z0-9_]*)["'']\s*,')
        frameworkPattern("state-bucket", state, ...
            '["''](inputs|parameters|annotations|results|extensions|selection|workflow|view|cache)["'']')
        frameworkPattern("state-root", stateValidation, ...
            '["''](project|session)["'']')
        frameworkPattern("callback-arity-probe", state, ...
            '(nargin|nargout)[(]')
        frameworkPattern("callback-arity-probe", stateValidation, ...
            '(nargin|nargout)[(]')
        frameworkPattern("callback-arity-probe", presentation, ...
            '(nargin|nargout)[(]')];
end

function spec = frameworkPattern(category, source, pattern)
    spec = struct("category", category, "source", source, ...
        "pattern", pattern);
end

function item = emptyFrameworkMatch()
    item = struct("category", "", "value", "", "source", "", "line", 0);
end

function paths = discoverVersionNamedPaths(repoRoot)
    entries = [ ...
        dir(fullfile(repoRoot, "**", "*.m"))
        dir(fullfile(repoRoot, "**", "*.md"))];
    values = strings(numel(entries), 1);
    cursor = 0;
    for k = 1:numel(entries)
        path = normalizedRelativePath(repoRoot, ...
            fullfile(entries(k).folder, entries(k).name));
        if startsWith(path, ["site/", "artifacts/", ".git/"])
            continue;
        end
        parts = lower(split(path, "/"));
        tokens = regexp(cellstr(parts), ...
            '(^|[^a-z])(v[0-9]+|version|legacy|compat)([^a-z]|$)', "once");
        if any(~cellfun("isempty", tokens))
            cursor = cursor + 1;
            values(cursor) = path;
        end
    end
    values = values(1:cursor);
    values = sort(unique(values));
    template = struct("path", "", "classification", "", "rationale", "");
    paths = repmat(template, numel(values), 1);
    for k = 1:numel(values)
        path = values(k);
        if endsWith(path, "/version.m") && startsWith(path, "+labkit/")
            classification = "allowed-facade-version";
            rationale = "Dedicated facade version metadata.";
        elseif startsWith(path, "docs/history/records/")
            classification = "allowed-history";
            rationale = "Immutable structured component history.";
        else
            classification = "prohibited-architecture-name";
            rationale = ...
                "Version, legacy, or compatibility naming outside approved metadata.";
        end
        paths(k) = struct("path", char(path), ...
            "classification", char(classification), ...
            "rationale", char(rationale));
    end
end

function summary = reportSummary( ...
        apps, matches, frameworkMatches, publicSymbols, versionPaths)
    classifications = string({versionPaths.classification});
    summary = struct( ...
        "appCount", numel(apps), ...
        "publicUiSymbolCount", numel(publicSymbols), ...
        "matchCount", numel(matches), ...
        "frameworkMatchCount", numel(frameworkMatches), ...
        "frameworkCategoryCount", ...
            numel(unique(string({frameworkMatches.category}))), ...
        "versionNamedPathCount", numel(versionPaths), ...
        "prohibitedArchitectureNameCount", ...
            nnz(classifications == "prohibited-architecture-name"));
end

function writeEvidence(outputRoot, report)
    if ~isfolder(outputRoot)
        mkdir(outputRoot);
    end
    json = string(jsonencode(report, PrettyPrint=true));
    writeText(fullfile(outputRoot, "baseline.json"), json + newline);
    writeText(fullfile(outputRoot, "capability-matrix.md"), ...
        capabilityMatrix(report));
    writeText(fullfile(outputRoot, "behavior-classification.md"), ...
        behaviorClassification(report));
end

function text = capabilityMatrix(report)
    categories = [ ...
        "definitionfield"
        "layoutconstructor"
        "presentationtransport"
        "interactionkind"
        "servicecall"
        "eventmeta"
        "registryaccess"
        "callbacksignature"];
    headings = [ ...
        "Definition"
        "Layout"
        "Presentation"
        "Interactions"
        "Services"
        "Event meta"
        "Registry"
        "Callbacks"];
    lines = [ ...
        "# UI explicit-contract Phase 0 capability matrix"
        ""
        "Generated by `tools/migration/auditLabKitUiMigration.m`. " + ...
            "Do not hand-edit counts."
        ""
        "| App | " + strjoin(headings, " | ") + " |"
        "| --- | " + strjoin(repmat("---", size(headings)), " | ") + " |"];
    appLines = strings(numel(report.apps), 1);
    for k = 1:numel(report.apps)
        counts = strings(size(categories));
        for iCategory = 1:numel(categories)
            category = report.apps(k).categories.(categories(iCategory));
            counts(iCategory) = string(numel(category.values)) + ...
                " (" + string(category.count) + ")";
        end
        appLines(k) = "| " + string(report.apps(k).title) + ...
            " | " + strjoin(counts, " | ") + " |";
    end
    lines = [lines; appLines; ...
        ""
        "## Inventory totals"
        ""
        "- Public `labkit.ui` symbols: " + ...
            string(report.summary.publicUiSymbolCount)
        "- App source matches: " + string(report.summary.matchCount)
        "- Framework shadow-contract matches: " + ...
            string(report.summary.frameworkMatchCount) + " across " + ...
            string(report.summary.frameworkCategoryCount) + " categories"
        "- Version-bearing paths requiring classification: " + ...
            string(report.summary.versionNamedPathCount)
        "- Prohibited version-bearing architecture paths: " + ...
            string(report.summary.prohibitedArchitectureNameCount)
        ""];
    text = strjoin(lines, newline);
end

function text = behaviorClassification(report)
    lines = [ ...
        "# Current UI call-pattern classification"
        ""
        "Generated by `tools/migration/auditLabKitUiMigration.m`. " + ...
            "Every distinct pattern is classified in `baseline.json`; this " + ...
            "file is the token-efficient decision summary."
        ""
        "| Category | Decision | Patterns | Apps | Uses | Owner | Test evidence |"
        "| --- | --- | ---: | ---: | ---: | --- | --- |"];
    patterns = report.callPatternClassifications;
    groupKeys = unique(string({patterns.category}).' + "|" + ...
        string({patterns.disposition}).' + "|" + ...
        string({patterns.owner}).' + "|" + ...
        string({patterns.testStrategy}).');
    patternLines = strings(numel(groupKeys), 1);
    for k = 1:numel(groupKeys)
        parts = split(groupKeys(k), "|");
        selected = string({patterns.category}) == parts(1) & ...
            string({patterns.disposition}) == parts(2) & ...
            string({patterns.owner}) == parts(3) & ...
            string({patterns.testStrategy}) == parts(4);
        selectedValues = string({patterns(selected).value});
        sourceMatches = report.matches( ...
            string({report.matches.category}) == parts(1) & ...
            ismember(string({report.matches.value}), selectedValues));
        patternLines(k) = "| " + escapeCell(parts(1)) + ...
            " | " + escapeCell(parts(2)) + " | " + ...
            string(nnz(selected)) + " | " + ...
            string(numel(unique(string({sourceMatches.appId})))) + " | " + ...
            string(sum([patterns(selected).occurrenceCount])) + " | " + ...
            escapeCell(parts(3)) + " | " + escapeCell(parts(4)) + " |";
    end
    lines = [lines; patternLines; ...
        ""
        "## Decision policy"
        ""
        "- `replace` retains the required capability through the accepted " + ...
            "strict contract, not through a production adapter."
        "- `remove` identifies accidental boundary exposure that the new " + ...
            "runtime must reject."
        "- Detailed rationale and every source location are machine-readable " + ...
            "in `baseline.json`."
        ""];
    text = strjoin(lines, newline);
end

function value = escapeCell(value)
    value = replace(string(value), "|", "\|");
end

function path = normalizedRelativePath(root, path)
    path = replace(extractAfter(string(path), string(root) + filesep), ...
        filesep, "/");
end

function writeText(filepath, text)
    fid = fopen(filepath, "w", "n", "UTF-8");
    if fid < 0
        error("LabKit:Migration:WriteFailed", ...
            "Could not write migration evidence: %s", filepath);
    end
    cleanup = onCleanup(@() fclose(fid));
    fwrite(fid, char(text), "char");
    clear cleanup
end
