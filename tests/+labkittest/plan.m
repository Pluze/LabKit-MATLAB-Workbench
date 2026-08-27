function result = plan(varargin)
%PLAN Compile a bounded LabKit test plan from semantic selectors.
%   RESULT = labkittest.plan(Profile="headless") selects every validated
%   headless specification. Profile="gui" selects hidden-GUI specifications;
%   Profile="journeys" selects every App-owned user workflow;
%   Profile="changed" derives the local pre-commit change set from Git and
%   compiles its bounded owner/contract evidence closure. It includes tracked
%   edits and untracked files; after a clean commit it reports that checkpoint.
%
%   RESULT = labkittest.plan(File=PATH), Owner=OWNER, Contract=CONTRACT, or
%   Environment=ENVIRONMENT compiles an exact plan without exposing folders,
%   substring name matching, tags, or executor switches. File is a repository
%   relative source path. Owner, Contract, and Environment use the same
%   semantics as labkittest.catalog.
%
%   RESULT has Descriptors, Groups, Reasons, Scope, Classifications, and
%   ManualChecks. Scope is focused-local or full-profile; it describes the
%   selected evidence shape and never upgrades local evidence into merge proof. A
%   manual check is an explicit non-automatable responsibility, never passing
%   automated evidence. The executor consumes this result directly and runs
%   each exact test identity once. SpecsRoot, RepositoryRoot, and ChangedPaths
%   exist for isolated framework self-tests; ordinary callers rely on
%   repository defaults.

    opts = parseOptions(varargin{:});
    [queries, reasons, manualChecks, classifications] = planQueries(opts);
    scope = scopeForOptions(opts);
    validateFocusedQueries(scope, queries);
    descriptors = descriptorsForQueries(opts, queries);
    if isempty(descriptors) && ~allowsNoAutomatedEvidence(scope, classifications)
        error("LabKit:TestPlan:NoEvidence", ...
            "The requested plan has no validated automated evidence.");
    end
    descriptors = uniqueDescriptors(descriptors);
    reportChangedPlan(opts, queries, descriptors, classifications);
    result = struct( ...
        "Descriptors", descriptors, ...
        "Groups", executionGroups(descriptors), ...
        "Reasons", reasons, ...
        "Fallback", false, ...
        "Scope", scope, ...
        "Classifications", classifications, ...
        "ManualChecks", manualChecks);
end

function opts = parseOptions(varargin)
    p = inputParser;
    p.FunctionName = "labkittest.plan";
    p.addParameter("Profile", "", @isTextScalar);
    p.addParameter("File", "", @isTextScalar);
    p.addParameter("Owner", "", @isTextScalar);
    p.addParameter("Contract", "", @isTextScalar);
    p.addParameter("Environment", "", @isTextScalar);
    p.addParameter("SpecsRoot", defaultSpecsRoot(), @isFolderPath);
    p.addParameter("RepositoryRoot", repositoryRoot(), @isFolderPath);
    p.addParameter("ChangedPaths", strings(1, 0), @isTextList);
    p.parse(varargin{:});
    opts = p.Results;
    opts.Profile = lower(strip(string(opts.Profile)));
    opts.File = normalizeRepositoryPath(opts.File);
    opts.Owner = string(opts.Owner);
    opts.Contract = string(opts.Contract);
    opts.Environment = string(opts.Environment);
    opts.SpecsRoot = string(opts.SpecsRoot);
    opts.RepositoryRoot = string(opts.RepositoryRoot);
    opts.ChangedPaths = normalizeRepositoryPath(opts.ChangedPaths);
    selectorCount = sum([strlength(opts.Profile) > 0, strlength(opts.File) > 0, ...
        strlength(opts.Owner) > 0, strlength(opts.Contract) > 0, ...
        strlength(opts.Environment) > 0]);
    if selectorCount == 0
        error("LabKit:TestPlan:MissingSelector", ...
            "Specify Profile, File, Owner, Contract, or Environment.");
    end
    if strlength(opts.Profile) > 0 && selectorCount > 1
        error("LabKit:TestPlan:AmbiguousSelector", ...
            "Profile cannot be combined with File, Owner, Contract, or Environment.");
    end
    if strlength(opts.File) > 0 && selectorCount > 1
        error("LabKit:TestPlan:AmbiguousSelector", ...
            "File cannot be combined with Owner, Contract, or Environment.");
    end
    if strlength(opts.Profile) > 0 && ~ismember(opts.Profile, ...
            ["changed", "headless", "gui", "isolated", "journeys", "coverage"])
        error("LabKit:TestPlan:UnknownProfile", ...
            "Profile must be changed, headless, gui, isolated, journeys, or coverage.");
    end
end

function [queries, reasons, manualChecks, classifications] = planQueries(opts)
    queries = repmat(emptyQuery(), 1, 0);
    reasons = strings(1, 0);
    manualChecks = strings(1, 0);
    classifications = repmat(emptyClassification(), 1, 0);
    if strlength(opts.Profile) > 0
        switch opts.Profile
            case "headless"
                queries = query("", "", "headless");
                reasons = "profile selects every headless specification";
            case "coverage"
                queries = [ ...
                    query("", "", "headless"), ...
                    query("", "workflow", "hidden-gui")];
                reasons = [ ...
                    "coverage profile selects every headless specification", ...
                    "coverage profile includes every native App user journey"];
            case "gui"
                queries = query("", "", "hidden-gui");
                reasons = "profile selects every hidden-GUI specification";
            case "journeys"
                queries = query("", "workflow", "hidden-gui");
                reasons = "profile selects every App-owned user workflow";
            case "isolated"
                queries = query("", "", "path-isolated");
                reasons = "profile selects every path-isolated specification";
            case "changed"
                paths = opts.ChangedPaths;
                if isempty(paths)
                    paths = gitChangedPaths(opts.RepositoryRoot);
                end
                [queries, reasons, manualChecks, classifications] = changedQueries(paths);
        end
        return;
    end
    if strlength(opts.File) > 0
        [queries, reasons, manualChecks, classifications] = queriesForChangedPath(opts.File);
        return;
    end
    queries = query(opts.Owner, opts.Contract, opts.Environment);
    reasons = "explicit semantic selector";
end

function [queries, reasons, manualChecks, classifications] = changedQueries(paths)
    queryChunks = cell(1, numel(paths));
    reasonChunks = cell(1, numel(paths));
    manualCheckChunks = cell(1, numel(paths));
    classifications = repmat(emptyClassification(), 1, numel(paths));
    for k = 1:numel(paths)
        [pathQueries, pathReasons, pathManualChecks, pathClassification] = queriesForChangedPath(paths(k));
        queryChunks{k} = pathQueries;
        reasonChunks{k} = pathReasons;
        manualCheckChunks{k} = pathManualChecks;
        classifications(k) = pathClassification;
    end
    queries = repmat(emptyQuery(), 1, 0);
    reasons = strings(1, 0);
    manualChecks = strings(1, 0);
    if ~isempty(paths)
        queries = [queryChunks{:}];
        reasons = [reasonChunks{:}];
        manualChecks = [manualCheckChunks{:}];
    end
    if isempty(queries)
        if isempty(paths)
            reasons = "no changed paths were found";
        end
    end
    manualChecks = unique(manualChecks(strlength(manualChecks) > 0), "stable");
end

function [queries, reasons, manualChecks, classification] = queriesForChangedPath(path)
    manualChecks = strings(1, 0);
    classification = labkittest.classifyPath(path);
    switch classification.Kind
        case "ignored"
            queries = repmat(emptyQuery(), 1, 0);
            reasons = "ignored: " + classification.Reason;
            return;
        case "unknown"
            error("LabKit:TestPlan:UnknownOwnership", ...
                "No validation ownership exists for: %s\n\n" + ...
                "The change either introduces a new production structure, is outside " + ...
                "an existing owner, requires a routing rule, or requires an explicit " + ...
                "no-test classification. Full CI cannot resolve missing ownership.", path);
    end
    if classification.Role == "specification"
        queries = query(classification.Owner, "", "");
        reasons = classification.Reason;
        return;
    end
    targets = labkittest.locate(path);
    queries = arrayfun(@(target) query(target.Owner, target.Contract, ...
        target.Environment, target.App), targets);
    reasons = string({targets.Reason});
    manualChecks = unique(string({targets.ManualCheck}), "stable");
    manualChecks = manualChecks(strlength(manualChecks) > 0);
end

function descriptors = descriptorsForQueries(opts, queries)
    descriptorChunks = cell(1, numel(queries));
    missingRequirements = strings(1, numel(queries));
    ownerCatalogs = containers.Map("KeyType", "char", "ValueType", "any");
    for k = 1:numel(queries)
        current = queries(k);
        ownerKey = char(lower(current.Owner));
        if ~isKey(ownerCatalogs, ownerKey)
            try
                ownerCatalogs(ownerKey) = labkittest.catalog( ...
                    "Owner", current.Owner, "SpecsRoot", opts.SpecsRoot);
            catch exception
                if exception.identifier == "LabKit:TestCatalog:UnknownOwner"
                    ownerCatalogs(ownerKey) = repmat(emptyDescriptor(), 1, 0);
                else
                    rethrow(exception)
                end
            end
        end
        selected = ownerCatalogs(ownerKey);
        if ~isempty(selected) && strlength(current.Contract) > 0
            selected = selected([selected.Contracts] == lower(current.Contract));
        end
        if ~isempty(selected) && strlength(current.Environment) > 0
            selected = selected([selected.Environment] == lower(current.Environment));
        end
        if strlength(current.App) > 0
            selected = selected(contains(string({selected.Id}), ...
                "(App=" + current.App + ")"));
        end
        if isempty(selected)
            missingRequirements(k) = sprintf( ...
                "owner=%s contract=%s environment=%s", ...
                current.Owner, current.Contract, current.Environment);
        end
        descriptorChunks{k} = selected;
    end
    missingRequirements = unique( ...
        missingRequirements(strlength(missingRequirements) > 0), "stable");
    if ~isempty(missingRequirements)
        error("LabKit:TestPlan:MissingContract", ...
            "Required evidence is missing for:\n%s", ...
            strjoin(missingRequirements, newline));
    end
    descriptors = repmat(emptyDescriptor(), 1, 0);
    if ~isempty(queries)
        descriptors = [descriptorChunks{:}];
    end
end

function reportChangedPlan(opts, queries, descriptors, classifications)
    if opts.Profile ~= "changed"
        return;
    end
    owners = string({queries.Owner});
    owners = owners(strlength(owners) > 0);
    fprintf("LabKit changed plan: paths=%d, evidence-owners=%d, " + ...
        "contract-queries=%d, unique-tests=%d\n", ...
        numel(classifications), numel(unique(lower(owners))), ...
        numel(queries), numel(descriptors));
end

function values = uniqueDescriptors(values)
    ids = lower(string({values.Id}));
    [~, indices] = unique(ids, "stable");
    values = values(sort(indices));
end

function groups = executionGroups(descriptors)
    environments = string({descriptors.Environment});
    names = unique(environments, "stable");
    groups = repmat(struct("Environment", "", "Descriptors", repmat(emptyDescriptor(), 1, 0)), ...
        1, numel(names));
    for k = 1:numel(names)
        groups(k).Environment = names(k);
        groups(k).Descriptors = descriptors(environments == names(k));
    end
end

function value = query(owner, contract, environment, app)
    if nargin < 4
        app = "";
    end
    value = struct("Owner", string(owner), "Contract", string(contract), ...
        "Environment", string(environment), "App", string(app));
end

function value = emptyQuery()
    value = query("", "", "");
end

function value = emptyClassification()
    value = struct("Path", "", "Kind", "", ...
        "Role", "", "Owner", "", "Reason", "");
end

function scope = scopeForOptions(opts)
    if strlength(opts.Profile) > 0
        if opts.Profile == "changed"
            scope = "focused-local";
        else
            scope = "full-profile";
        end
        return;
    end
    if strlength(opts.File) > 0
        scope = "focused-local";
        return;
    end
    if strlength(opts.Environment) > 0 && strlength(opts.Owner) == 0 && ...
            strlength(opts.Contract) == 0
        scope = "full-profile";
    else
        scope = "focused-local";
    end
end

function validateFocusedQueries(scope, queries)
    if scope ~= "focused-local"
        return;
    end
    for k = 1:numel(queries)
        current = queries(k);
        if strlength(current.Owner) == 0 && strlength(current.Contract) == 0 && ...
                strlength(current.App) == 0
            error("LabKit:TestPlan:UnboundedFocusedPlan", ...
                "Focused validation must select bounded owner, contract, or App evidence.");
        end
    end
end

function tf = allowsNoAutomatedEvidence(scope, classifications)
tf = scope == "focused-local" && ~isempty(classifications) && ...
    all(string({classifications.Kind}) == "ignored");
end

function value = emptyDescriptor()
    value = struct("Id", "", "Owner", "", "Contracts", strings(1, 0), ...
        "Environment", "", "Test", matlab.unittest.Test.empty(1, 0));
end

function root = defaultSpecsRoot()
    packageFolder = fileparts(mfilename("fullpath"));
    root = fullfile(fileparts(fileparts(packageFolder)), "tests", "specs");
end

function root = repositoryRoot()
    packageFolder = fileparts(mfilename("fullpath"));
    root = fileparts(fileparts(packageFolder));
end

function paths = gitChangedPaths(root)
    tracked = gitOutput(root, ...
        "diff --name-only --diff-filter=ACMRTUXB HEAD");
    untracked = gitOutput(root, "ls-files --others --exclude-standard");
    paths = unique(normalizeRepositoryPath([splitlines(tracked); splitlines(untracked)]), ...
        "stable");
    paths = paths(strlength(paths) > 0);
    if ~isempty(paths) || ~gitRefExists(root, "HEAD~1")
        return;
    end
    output = gitOutput(root, ...
        "diff --name-only --diff-filter=ACMRTUXB HEAD~1 HEAD");
    paths = normalizeRepositoryPath(splitlines(output));
    paths = paths(strlength(paths) > 0).';
end

function output = gitOutput(root, gitArguments)
    command = "git -c core.safecrlf=false --no-pager -C " + ...
        shellQuote(root) + " " + gitArguments;
    % Secondary-runtime test boundary: Git selects changed test ownership.
    [status, output] = system(char(command));
    if status ~= 0
        error("LabKit:TestPlan:GitInspection", ...
            "Could not inspect local pre-commit changes with git: %s", strtrim(output));
    end
    output = string(output);
end

function tf = gitRefExists(root, reference)
    command = "git -c core.safecrlf=false --no-pager -C " + ...
        shellQuote(root) + " rev-parse --verify --quiet " + reference;
    % Secondary-runtime test boundary: Git confirms the comparison baseline.
    [status, ~] = system(char(command));
    tf = status == 0;
end

function value = shellQuote(value)
    quote = string(char(34));
    value = quote + replace(string(value), quote, "\\" + quote) + quote;
end

function value = normalizeRepositoryPath(value)
    value = strip(replace(string(value), "\", "/"));
    value = value(:).';
    if any(startsWith(value, "/") | contains(value, "..") | contains(value, ":"))
        error("LabKit:TestPlan:InvalidPath", ...
            "File and ChangedPaths must be repository-relative paths.");
    end
end

function tf = isTextScalar(value)
    tf = ischar(value) || (isstring(value) && isscalar(value));
end

function tf = isFolderPath(value)
    tf = isTextScalar(value) && exist(char(value), "dir") == 7;
end

function tf = isTextList(value)
    tf = ischar(value) || isstring(value) || iscellstr(value);
end
