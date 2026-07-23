function result = plan(varargin)
%PLAN Compile a bounded LabKit test plan from semantic selectors.
%   RESULT = labkittest.plan(Profile="headless") selects every validated
%   headless specification. Profile="gui" selects hidden-GUI specifications;
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
%   RESULT has Descriptors, Groups, Reasons, Fallback, and ManualChecks. The
%   executor consumes this result directly and runs each exact test identity
%   once. SpecsRoot, RepositoryRoot, and ChangedPaths exist for isolated
%   framework self-tests; ordinary callers rely on repository defaults.

    opts = parseOptions(varargin{:});
    [queries, reasons, fallback] = planQueries(opts);
    descriptors = descriptorsForQueries(opts, queries);
    if isempty(descriptors)
        error("LabKit:TestPlan:NoEvidence", ...
            "The requested plan has no validated automated evidence.");
    end
    descriptors = uniqueDescriptors(descriptors);
    result = struct( ...
        "Descriptors", descriptors, ...
        "Groups", executionGroups(descriptors), ...
        "Reasons", reasons, ...
        "Fallback", fallback, ...
        "ManualChecks", strings(1, 0));
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
            ["changed", "headless", "gui", "coverage"])
        error("LabKit:TestPlan:UnknownProfile", ...
            "Profile must be changed, headless, gui, or coverage.");
    end
end

function [queries, reasons, fallback] = planQueries(opts)
    fallback = false;
    queries = repmat(emptyQuery(), 1, 0);
    reasons = strings(1, 0);
    if strlength(opts.Profile) > 0
        switch opts.Profile
            case {"headless", "coverage"}
                queries = query("", "", "headless");
                reasons = "profile selects every headless specification";
            case "gui"
                queries = query("", "", "hidden-gui");
                reasons = "profile selects every hidden-GUI specification";
            case "changed"
                paths = opts.ChangedPaths;
                if isempty(paths)
                    paths = gitChangedPaths(opts.RepositoryRoot);
                end
                [queries, reasons, fallback] = changedQueries(paths);
        end
        return;
    end
    if strlength(opts.File) > 0
        [queries, reasons, fallback] = queriesForChangedPath(opts.File);
        return;
    end
    queries = query(opts.Owner, opts.Contract, opts.Environment);
    reasons = "explicit semantic selector";
end

function [queries, reasons, fallback] = changedQueries(paths)
    queries = repmat(emptyQuery(), 1, 0);
    reasons = strings(1, 0);
    fallback = false;
    for k = 1:numel(paths)
        [pathQueries, pathReasons, pathFallback] = queriesForChangedPath(paths(k));
        queries = [queries, pathQueries];
        reasons = [reasons, pathReasons];
        fallback = fallback || pathFallback;
    end
    if isempty(queries)
        [queries, reasons, fallback] = fullHeadlessFallback("no changed paths were found");
    end
end

function [queries, reasons, fallback] = queriesForChangedPath(path)
    if startsWith(path, "tests/specs/")
        [folder, ~, ~] = fileparts(char(path));
        owner = extractAfter(string(folder), "tests/specs/");
        queries = query(owner, "", "");
        reasons = "changed specification selects its physical owner";
        fallback = false;
        return;
    end
    try
        targets = labkittest.locate(path);
        queries = arrayfun(@(target) query(target.Owner, target.Contract, ...
            target.Environment, target.App), targets);
        reasons = string({targets.Reason});
        fallback = false;
    catch exception
        if exception.identifier ~= "LabKit:TestLocation:UnknownSource"
            rethrow(exception)
        end
        [queries, reasons, fallback] = fullHeadlessFallback( ...
            "path has no bounded source-owner rule: " + path);
    end
end

function [queries, reasons, fallback] = fullHeadlessFallback(reason)
    queries = query("", "", "headless");
    reasons = "conservative fallback: " + reason;
    fallback = true;
end

function descriptors = descriptorsForQueries(opts, queries)
    descriptors = repmat(emptyDescriptor(), 1, 0);
    for k = 1:numel(queries)
        current = queries(k);
        try
            selected = labkittest.catalog( ...
                "Owner", current.Owner, ...
                "Contract", current.Contract, ...
                "Environment", current.Environment, ...
                "SpecsRoot", opts.SpecsRoot);
        catch exception
            if exception.identifier == "LabKit:TestCatalog:UnknownOwner"
                selected = repmat(emptyDescriptor(), 1, 0);
            else
                rethrow(exception)
            end
        end
        if strlength(current.App) > 0
            selected = selected(contains(string({selected.Id}), ...
                "(App=" + current.App + ")"));
        end
        if isempty(selected)
            error("LabKit:TestPlan:MissingContract", ...
                "Required evidence is missing for owner=%s contract=%s environment=%s.", ...
                current.Owner, current.Contract, current.Environment);
        end
        descriptors = [descriptors, selected];
    end
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
    tracked = gitOutput(root, "diff --name-only HEAD");
    untracked = gitOutput(root, "ls-files --others --exclude-standard");
    paths = unique(normalizeRepositoryPath([splitlines(tracked); splitlines(untracked)]), ...
        "stable");
    paths = paths(strlength(paths) > 0);
    if ~isempty(paths) || ~gitRefExists(root, "HEAD^")
        return;
    end
    output = gitOutput(root, "diff --name-only HEAD^ HEAD");
    paths = normalizeRepositoryPath(splitlines(output));
    paths = paths(strlength(paths) > 0).';
end

function output = gitOutput(root, gitArguments)
    command = "git -C " + shellQuote(root) + " " + gitArguments;
    [status, output] = system(char(command));
    if status ~= 0
        error("LabKit:TestPlan:GitInspection", ...
            "Could not inspect local pre-commit changes with git: %s", strtrim(output));
    end
    output = string(output);
end

function tf = gitRefExists(root, reference)
    command = "git -C " + shellQuote(root) + " rev-parse --verify --quiet " + reference;
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
