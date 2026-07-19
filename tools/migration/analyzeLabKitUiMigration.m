function report = analyzeLabKitUiMigration(repoRoot, options)
%ANALYZELABKITUIMIGRATION Report retired App-facing UI patterns offline.
%
% Usage:
%   report = analyzeLabKitUiMigration
%   report = analyzeLabKitUiMigration(repoRoot)
%   report = analyzeLabKitUiMigration(repoRoot, App="video-marker")
%   analyzeLabKitUiMigration(repoRoot, FailOnRetired=true)
%
% Description:
%   Performs a read-only source analysis for the UI explicit-contract
%   migration. Diagnostics cover current definition fields, layout
%   constructors, raw presentation paths, interaction kinds/fields/options,
%   generic event decoding, service calls, registry access, callback shapes,
%   and framework aliases. Each diagnostic includes a source location and one
%   replacement direction. This tool is not part of the App runtime.
%
% Inputs:
%   repoRoot - LabKit repository root. Default: repository containing this
%       function.
%
% Name-Value Arguments:
%   App - Optional App ID, command, or title. Default: all public Apps.
%   Write - Write migration-worksheet.md under OutputRoot. Default: false.
%   WriteDiagnostics - With Write=true, also write the complete source-location
%       migration-analysis.json. Default: false.
%   OutputRoot - Evidence folder. Default:
%       .agents/migration/ui-explicit-contract beneath repoRoot.
%   FailOnRetired - Throw when any retired pattern remains. This is the
%       post-migration guard mode. Default: false.
%
% Outputs:
%   report - Scalar structure with diagnostics, worksheet, and summary.
%
% Errors:
%   LabKit:Migration:UnknownApp - App does not identify one cataloged App.
%   LabKit:Migration:RetiredUiBoundary - FailOnRetired found a retired use.
%   LabKit:Migration:WriteFailed - Evidence cannot be written.
%
% Side effects:
%   None unless Write=true. FailOnRetired may throw after analysis.
%
% Example:
%   report = analyzeLabKitUiMigration(pwd, App="curvature");
%   assert(report.summary.appCount == 1)
%
% See also auditLabKitUiMigration

    arguments
        repoRoot (1, 1) string = defaultRepositoryRoot()
        options.App (1, 1) string = ""
        options.Write (1, 1) logical = false
        options.WriteDiagnostics (1, 1) logical = false
        options.OutputRoot (1, 1) string = ""
        options.FailOnRetired (1, 1) logical = false
    end
    repoRoot = validateRoot(repoRoot);
    if strlength(options.OutputRoot) == 0
        options.OutputRoot = fullfile(repoRoot, ".agents", "migration", ...
            "ui-explicit-contract");
    end
    toolRoot = fullfile(repoRoot, "tools", "migration");
    oldPath = path;
    cleanup = onCleanup(@() path(oldPath));
    addpath(toolRoot, "-begin");

    audit = auditLabKitUiMigration(repoRoot);
    apps = selectedApps(audit.apps, options.App);
    appIds = string({apps.id});
    baseMatches = audit.matches(ismember( ...
        string({audit.matches.appId}), appIds));
    diagnostics = diagnosticsFromAudit(baseMatches);
    diagnostics = [diagnostics; scanSupplemental(repoRoot, apps)];
    if strlength(options.App) == 0
        diagnostics = [diagnostics; scanFrameworkAliases(repoRoot)];
    end
    diagnostics = sortDiagnostics(diagnostics);
    worksheet = buildWorksheet(diagnostics);
    report = struct( ...
        "schemaVersion", 1, ...
        "apps", apps, ...
        "diagnostics", diagnostics, ...
        "worksheet", worksheet, ...
        "summary", struct( ...
            "appCount", numel(apps), ...
            "diagnosticCount", numel(diagnostics), ...
            "worksheetEntryCount", numel(worksheet), ...
            "retiredDiagnosticCount", nnz([diagnostics.retired]), ...
            "mechanicalCandidateCount", ...
                nnz([diagnostics.mechanicalCandidate]), ...
            "frameworkAliasCount", nnz( ...
                string({diagnostics.category}) == "undocumented-alias")));
    if options.Write
        writeEvidence(options.OutputRoot, report, options.WriteDiagnostics);
    end
    retired = diagnostics([diagnostics.retired]);
    if options.FailOnRetired && ~isempty(retired)
        first = retired(1);
        error("LabKit:Migration:RetiredUiBoundary", ...
            "Retired UI boundary remains at %s:%d (%s: %s).", ...
            first.source, first.line, first.category, first.value);
    end
    clear cleanup
end

function apps = selectedApps(apps, requested)
    if strlength(requested) == 0
        return;
    end
    requested = lower(requested);
    matched = lower(string({apps.id})) == requested | ...
        lower(string({apps.command})) == requested | ...
        lower(string({apps.title})) == requested;
    if nnz(matched) ~= 1
        error("LabKit:Migration:UnknownApp", ...
            "App must identify exactly one cataloged public App: %s", ...
            requested);
    end
    apps = apps(matched);
end

function diagnostics = diagnosticsFromAudit(matches)
    diagnostics = repmat(emptyDiagnostic(), numel(matches), 1);
    for k = 1:numel(matches)
        category = string(matches(k).category);
        value = string(matches(k).value);
        [replacement, mechanical, retired] = ...
            replacementFor(category, value);
        diagnostics(k) = struct( ...
            "appId", matches(k).appId, ...
            "category", char(category), ...
            "value", char(value), ...
            "source", matches(k).source, ...
            "line", matches(k).line, ...
            "column", 0, ...
            "confidence", matches(k).confidence, ...
            "semanticRole", matches(k).semanticRole, ...
            "reviewed", matches(k).reviewed, ...
            "replacement", char(replacement), ...
            "mechanicalCandidate", mechanical, ...
            "retired", retired);
    end
end

function diagnostics = scanSupplemental(repoRoot, apps)
    specs = supplementalSpecs();
    chunks = cell(numel(apps), 1);
    for iApp = 1:numel(apps)
        root = fullfile(repoRoot, apps(iApp).folder);
        entries = dir(fullfile(root, "**", "*.m"));
        appChunks = cell(numel(entries), 1);
        for iFile = 1:numel(entries)
            filepath = string(fullfile(entries(iFile).folder, ...
                entries(iFile).name));
            source = relativePath(repoRoot, filepath);
            lines = readlines(filepath, "EmptyLineRule", "read");
            fileMatches = cell(numel(specs), 1);
            for iSpec = 1:numel(specs)
                if ~specs(iSpec).applies(source)
                    fileMatches{iSpec} = repmat(emptyDiagnostic(), 0, 1);
                    continue;
                end
                fileMatches{iSpec} = matchLines( ...
                    apps(iApp).id, source, lines, specs(iSpec));
            end
            appChunks{iFile} = vertcat(fileMatches{:});
        end
        chunks{iApp} = vertcat(appChunks{:});
    end
    diagnostics = vertcat(chunks{:});
end

function specs = supplementalSpecs()
    presenter = @(source) endsWith( ...
        source, "/+userInterface/presentWorkbench.m");
    anyApp = @(source) startsWith(source, "apps/");
    specs = [ ...
        diagnosticSpec("definition-call", ...
            'labkit[.]ui[.]runtime[.]define', ...
            @(source) endsWith(source, "/definition.m"))
        diagnosticSpec("raw-presentation-path", ...
            'view[.](controls|previews|interactions)(?:[.]([A-Za-z][A-Za-z0-9_]*))?(?:[.]([A-Za-z][A-Za-z0-9_]*))?', ...
            presenter)
        diagnosticSpec("interaction-field", ...
            '["''](Kind|Targets|Value|Event|BackgroundEvent|ScrollEvent|ChangePolicy|ImageSize|Options|Instruction)["'']\s*,', ...
            presenter)
        diagnosticSpec("interaction-option", ...
            '["''](mode|color|faceColor|faceAlpha|lineWidth|lineStyle|pointThreshold|maxPoints|closed|style)["'']\s*,', ...
            presenter)
        diagnosticSpec("event-decoding", ...
            'services[.]events[.](entries|paths|indices)', anyApp)
        diagnosticSpec("retired-callback-context", ...
            '^\s*function\s+[^(]*[(][^)]*(event|services)[^)]*[)]', ...
            anyApp)];
end

function spec = diagnosticSpec(category, pattern, applies)
    spec = struct("category", category, "pattern", pattern, ...
        "applies", applies);
end

function diagnostics = matchLines(appId, source, lines, spec)
    tokenSets = regexp(cellstr(lines), spec.pattern, "tokens");
    tokenSets(startsWith(strip(lines), "%")) = {{}};
    count = sum(cellfun(@numel, tokenSets));
    diagnostics = repmat(emptyDiagnostic(), count, 1);
    cursor = 0;
    for iLine = 1:numel(lines)
        tokens = tokenSets{iLine};
        for iToken = 1:numel(tokens)
            values = string(tokens{iToken});
            values = values(strlength(values) > 0);
            value = strjoin(values, ".");
            [replacement, mechanical, retired] = replacementFor( ...
                spec.category, value);
            start = regexp(char(lines(iLine)), spec.pattern, "start", "once");
            cursor = cursor + 1;
            diagnostics(cursor) = struct( ...
                "appId", char(appId), ...
                "category", char(spec.category), ...
                "value", char(value), ...
                "source", char(source), ...
                "line", double(iLine), ...
                "column", double(start), ...
                "confidence", "exact", ...
                "semanticRole", char(diagnosticRole(spec.category)), ...
                "reviewed", true, ...
                "replacement", char(replacement), ...
                "mechanicalCandidate", mechanical, ...
                "retired", retired);
        end
    end
end

function diagnostics = scanFrameworkAliases(repoRoot)
    probes = [ ...
        aliasProbe("+labkit/+ui/+layout/field.m", ...
            'strcmpi[(]kind', "case-insensitive field kind")
        aliasProbe("+labkit/+ui/+runtime/private/prepareV2Layout.m", ...
            'strcmpi[(]names', "case-insensitive binding property")
        aliasProbe("+labkit/+ui/+runtime/private/commitV2Presentation.m", ...
            'strcmpi[(]fields', "case-insensitive presentation property")
        aliasProbe("+labkit/+ui/+runtime/private/reconcileV2Interactions.m", ...
            'lower[(]spec[.]Kind[)]', "case-insensitive interaction kind")];
    chunks = cell(numel(probes), 1);
    for k = 1:numel(probes)
        lines = readlines(fullfile(repoRoot, probes(k).source), ...
            "EmptyLineRule", "read");
        indices = find(~cellfun("isempty", ...
            regexp(cellstr(lines), probes(k).pattern, "once")));
        chunk = repmat(emptyDiagnostic(), numel(indices), 1);
        for j = 1:numel(indices)
            line = indices(j);
            column = regexp(char(lines(line)), probes(k).pattern, ...
                "start", "once");
            chunk(j) = struct( ...
                "appId", "<framework>", ...
                "category", "undocumented-alias", ...
                "value", char(probes(k).value), ...
                "source", char(probes(k).source), ...
                "line", double(line), ...
                "column", double(column), ...
                "confidence", "exact", ...
                "semanticRole", "framework-alias", ...
                "reviewed", true, ...
                "replacement", ...
                    "exact canonical spelling validated at construction", ...
                "mechanicalCandidate", false, ...
                "retired", true);
        end
        chunks{k} = chunk;
    end
    diagnostics = vertcat(chunks{:});
end

function probe = aliasProbe(source, pattern, value)
    probe = struct("source", source, "pattern", pattern, "value", value);
end

function [replacement, mechanical, retired] = replacementFor(category, value)
    mechanical = false;
    retired = true;
    switch category
        case "definition-field"
            replacement = "labkit.ui.application owned constructor/composition";
            retired = false;
        case "definition-call"
            replacement = "labkit.ui.application";
        case "layout-constructor"
            replacement = "strict labkit.ui.layout." + value + " value";
            retired = false;
        case {"presentation-transport", "raw-presentation-path"}
            replacement = "closed labkit.ui.presentation operation";
        case "interaction-kind"
            replacement = interactionReplacement(value);
        case {"interaction-field", "interaction-option"}
            replacement = "named strict interaction constructor parameter";
        case "event-decoding"
            replacement = "role-specific typed signal payload";
        case "service-call"
            replacement = serviceReplacement(value);
        case "event-meta"
            replacement = "role-specific typed signal payload";
        case "registry-access"
            replacement = "remove; use declared target/context capability";
        case "callback-signature"
            name = extractBefore(value + ".", ".");
            if startsWith(name, "on")
                replacement = ...
                    "labkit.ui.command with declared callback Role";
            elseif name == "createSession"
                replacement = "Application session factory";
            elseif name == "initializeWorkbench"
                replacement = "Application startup callback";
            else
                replacement = "typed ProjectContract callback";
            end
            retired = false;
        case "retired-callback-context"
            replacement = "role-specific value/selection/edit payload and RuntimeContext";
        otherwise
            replacement = "architecture worksheet review";
            retired = false;
    end
end

function replacement = interactionReplacement(value)
    switch lower(value)
        case "anchors"
            replacement = "labkit.ui.interaction.anchorPath";
        case "pairedanchors"
            replacement = "labkit.ui.interaction.pairedAnchors";
        case "pointslots"
            replacement = "labkit.ui.interaction.pointSlots";
        case "rectangle"
            replacement = "labkit.ui.interaction.rectangle";
        case "regionselection"
            replacement = "labkit.ui.interaction.regionSelection";
        case "interval"
            replacement = "labkit.ui.interaction.interval";
        case "scalebarreference"
            replacement = "labkit.ui.interaction.scaleReference";
        otherwise
            replacement = "named interaction constructor review";
    end
end

function replacement = serviceReplacement(value)
    group = extractBefore(value + ".", ".");
    switch group
        case {"debug", "request"}
            replacement = "remove exposed runtime internals";
        case "diagnostics"
            replacement = "context.reportError";
        case "dialogs"
            replacement = "typed context dialog/chooser method";
        case "events"
            replacement = "typed signal payload";
        case "previews"
            replacement = "declared preview target or interaction";
        case "project"
            replacement = "typed context project/source method";
        case "resources"
            replacement = "typed context resource lifecycle method";
        case "results"
            replacement = "validated result value and context.writeResult";
        case "workflow"
            replacement = "context.appendStatus";
        otherwise
            replacement = "documented RuntimeContext method";
    end
end

function diagnostics = sortDiagnostics(diagnostics)
    if isempty(diagnostics)
        return;
    end
    keys = string({diagnostics.appId}).' + "|" + ...
        string({diagnostics.source}).' + "|" + ...
        compose("%08d", [diagnostics.line].') + "|" + ...
        string({diagnostics.category}).' + "|" + ...
        string({diagnostics.value}).';
    [~, order] = sort(keys);
    diagnostics = diagnostics(order);
    uniqueKeys = keys(order);
    diagnostics = diagnostics([true; uniqueKeys(2:end) ~= uniqueKeys(1:end-1)]);
end

function worksheet = buildWorksheet(diagnostics)
    if isempty(diagnostics)
        worksheet = repmat(emptyWorksheet(), 0, 1);
        return;
    end
    keys = unique(string({diagnostics.category}).' + "|" + ...
        string({diagnostics.value}).' + "|" + ...
        string({diagnostics.replacement}).');
    worksheet = repmat(emptyWorksheet(), numel(keys), 1);
    for k = 1:numel(keys)
        parts = split(keys(k), "|");
        selected = string({diagnostics.category}) == parts(1) & ...
            string({diagnostics.value}) == parts(2) & ...
            string({diagnostics.replacement}) == parts(3);
        worksheet(k) = struct( ...
            "category", char(parts(1)), ...
            "currentPattern", char(parts(2)), ...
            "replacement", char(parts(3)), ...
            "appCount", numel(unique(string( ...
                {diagnostics(selected).appId}))), ...
            "occurrenceCount", nnz(selected), ...
            "mechanicalCandidate", ...
                all([diagnostics(selected).mechanicalCandidate]), ...
            "retired", any([diagnostics(selected).retired]));
    end
end

function value = emptyDiagnostic()
    value = struct("appId", "", "category", "", "value", "", ...
        "source", "", "line", 0, "column", 0, "confidence", "", ...
        "semanticRole", "", "reviewed", false, "replacement", "", ...
        "mechanicalCandidate", false, "retired", false);
end

function role = diagnosticRole(category)
    switch string(category)
        case {"retired-callback-context", "event-decoding"}
            role = "ui-callback";
        case "definition-call"
            role = "metadata";
        case "undocumented-alias"
            role = "framework-alias";
        otherwise
            role = "ui-boundary";
    end
end

function value = emptyWorksheet()
    value = struct("category", "", "currentPattern", "", ...
        "replacement", "", "appCount", 0, "occurrenceCount", 0, ...
        "mechanicalCandidate", false, "retired", false);
end

function writeEvidence(outputRoot, report, writeDiagnostics)
    if ~isfolder(outputRoot)
        mkdir(outputRoot);
    end
    if writeDiagnostics
        writeText(fullfile(outputRoot, "migration-analysis.json"), ...
            string(jsonencode(report, PrettyPrint=true)) + newline);
    end
    writeText(fullfile(outputRoot, "migration-worksheet.md"), ...
        worksheetMarkdown(report));
end

function text = worksheetMarkdown(report)
    categories = unique(string({report.worksheet.category}));
    lines = [ ...
        "# UI migration worksheet"
        ""
        "Generated by `analyzeLabKitUiMigration`. Source locations and every " + ...
            "distinct pattern are in `migration-analysis.json`."
        ""
        "| Category | Retired | Patterns | Apps | Uses | Replacement direction |"
        "| --- | --- | ---: | ---: | ---: | --- |"];
    rows = strings(numel(categories), 1);
    for k = 1:numel(categories)
        selected = string({report.worksheet.category}) == categories(k);
        entries = report.worksheet(selected);
        categoryDiagnostics = report.diagnostics( ...
            string({report.diagnostics.category}) == categories(k));
        replacements = unique(string({entries.replacement}));
        rows(k) = "| " + categories(k) + " | " + ...
            string(any([entries.retired])) + " | " + ...
            string(numel(entries)) + " | " + ...
            string(numel(unique(string( ...
                {categoryDiagnostics.appId})))) + " | " + ...
            string(sum([entries.occurrenceCount])) + " | " + ...
            strjoin(replacements, "; ") + " |";
    end
    lines = [lines; rows; ...
        ""
        "Mechanical candidates: " + ...
            string(report.summary.mechanicalCandidateCount) + ...
            ". All generated edits remain reviewed source; this analyzer " + ...
            "does not guarantee semantic correctness."
        ""];
    text = strjoin(lines, newline);
end

function root = defaultRepositoryRoot()
    root = string(fileparts(fileparts(fileparts(mfilename("fullpath")))));
end

function root = validateRoot(root)
    [ok, attributes] = fileattrib(root);
    if ~ok || ~attributes.directory || ...
            ~isfile(fullfile(attributes.Name, "labkit_launcher.m"))
        error("LabKit:Migration:InvalidRoot", ...
            "Not a LabKit repository root: %s", root);
    end
    root = string(attributes.Name);
end

function path = relativePath(root, path)
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
