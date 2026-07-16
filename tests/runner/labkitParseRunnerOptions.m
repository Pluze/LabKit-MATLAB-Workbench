function opts = labkitParseRunnerOptions(root, varargin)
%LABKITPARSERUNNEROPTIONS Parse runLabKitTests name-value options.
% Expected caller: runLabKitTests.
% Inputs:
%   root     repository root used for default artifact paths
%   varargin runLabKitTests name-value arguments
% Output:
%   opts     normalized runner options struct
% Side effects: none.

    p = inputParser;
    p.FunctionName = "runLabKitTests";
    p.addParameter("IncludeGui", false, @isLogicalScalar);
    p.addParameter("Suites", strings(1, 0), @isStringLikeList);
    p.addParameter("Files", strings(1, 0), @isStringLikeList);
    p.addParameter("Tests", strings(1, 0), @isStringLikeList);
    p.addParameter("Tags", strings(1, 0), @isStringLikeList);
    p.addParameter("ExcludeTags", strings(1, 0), @isStringLikeList);
    p.addParameter("Plan", "", @isTextScalar);
    p.addParameter("IncludeCoverage", false, @isLogicalScalar);
    p.addParameter("GuiMode", labkitDefaultGuiMode(), @isTextScalar);
    p.addParameter("HtmlReport", true, @isLogicalScalar);
    p.addParameter("FailIfNoTests", true, @isLogicalScalar);
    p.addParameter("ArtifactsRoot", fullfile(root, "artifacts"), @isTextScalar);
    p.addParameter("RunName", "local", @isTextScalar);
    p.addParameter("ListOnly", false, @isLogicalScalar);
    p.addParameter("OutputDetail", "Concise", @isTextScalar);
    p.addParameter("LoggingLevel", "Concise", @isTextScalar);
    p.addParameter("ShardCount", 1, @isPositiveIntegerScalar);
    p.addParameter("ShardIndex", 0, @isNonnegativeIntegerScalar);
    p.parse(varargin{:});

    opts = p.Results;
    opts.IncludeGui = logical(opts.IncludeGui);
    opts.IncludeCoverage = logical(opts.IncludeCoverage);
    opts.GuiMode = labkitNormalizeGuiMode(opts.GuiMode);
    opts.HtmlReport = logical(opts.HtmlReport);
    opts.FailIfNoTests = logical(opts.FailIfNoTests);
    opts.ListOnly = logical(opts.ListOnly);
    opts.Suites = labkitNormalizeSuiteTargets(opts.Suites);
    opts.Files = labkitNormalizeTestFileSelectors(root, opts.Files);
    opts.Tests = normalizeTextList(opts.Tests);
    opts.Tags = normalizeTextList(opts.Tags);
    opts.ExcludeTags = normalizeTextList(opts.ExcludeTags);
    opts.Plan = lower(string(opts.Plan));
    opts.ArtifactsRoot = char(opts.ArtifactsRoot);
    opts.RunName = string(opts.RunName);
    opts.ShardCount = double(opts.ShardCount);
    opts.ShardIndex = double(opts.ShardIndex);
    if ~isempty(opts.Suites) && ~isempty(opts.Files)
        error("LabKit:Tests:ConflictingSelectors", ...
            "Suites and Files are alternative scopes; specify only one.");
    end
    if opts.ShardIndex >= opts.ShardCount
        error("LabKit:Tests:InvalidShard", ...
            "ShardIndex must be less than ShardCount.");
    end
end

function values = normalizeTextList(values)
    if isempty(values)
        values = strings(1, 0);
    elseif ischar(values)
        values = string({values});
    elseif iscell(values)
        values = string(values);
    else
        values = string(values);
    end
    values = values(:).';
    values = values(strlength(values) > 0);
end

function tf = isStringLikeList(value)
    tf = ischar(value) || isstring(value) || iscellstr(value);
end

function tf = isTextScalar(value)
    tf = (ischar(value) || (isstring(value) && isscalar(value)));
end

function tf = isLogicalScalar(value)
    tf = (islogical(value) || isnumeric(value)) && isscalar(value) && ...
        isfinite(double(value));
end

function tf = isPositiveIntegerScalar(value)
    tf = isnumeric(value) && isscalar(value) && isfinite(value) && ...
        value >= 1 && fix(value) == value;
end

function tf = isNonnegativeIntegerScalar(value)
    tf = isnumeric(value) && isscalar(value) && isfinite(value) && ...
        value >= 0 && fix(value) == value;
end

function files = labkitNormalizeTestFileSelectors(root, values)
    values = normalizeTextList(values);
    casesRoot = canonicalPath(fullfile(root, "tests", "cases"));
    files = strings(1, numel(values));
    for k = 1:numel(values)
        value = strip(values(k));
        candidates = [value, string(fullfile(root, value)), ...
            string(fullfile(casesRoot, value))];
        candidate = candidates(find(arrayfun(@isfile, candidates), 1));
        if isempty(candidate)
            error("LabKit:Tests:TestFileNotFound", ...
                "Official test file does not exist: %s", value);
        end
        candidate = canonicalPath(candidate);
        if ~startsWith(candidate, casesRoot + filesep) || ...
                ~endsWith(lower(candidate), ".m")
            error("LabKit:Tests:TestFileOutsideCases", ...
                "Files must select .m tests under tests/cases: %s", value);
        end
        files(k) = candidate;
    end
    files = unique(files, "stable");
end

function path = canonicalPath(path)
    [status, attributes] = fileattrib(path);
    if ~status
        error("LabKit:Tests:UnresolvablePath", ...
            "Could not resolve test path: %s", string(path));
    end
    path = string(attributes.Name);
end
