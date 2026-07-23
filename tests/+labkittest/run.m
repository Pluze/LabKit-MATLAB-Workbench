function result = run(varargin)
%RUN Execute a compiled LabKit test plan with one runner per environment.
%   RESULT = labkittest.run accepts the same semantic selectors as
%   labkittest.plan, compiles a plan, and runs each exact test identity once.
%   It never accepts suite folders, substring test names, arbitrary tags, or
%   runner options.
%
%   RESULT = labkittest.run(Plan=PLAN) executes an already compiled plan.
%   PLAN must be the value returned by labkittest.plan. RunName and
%   ArtifactsRoot control the run-centered artifact folder; ordinary callers
%   use the defaults.
%
%   The initial implementation writes the exact test result objects. The
%   migrated build integration adds JUnit, events, summary, and MATLAB-log
%   artifacts to the same run folder before legacy artifacts are deleted.

    [compiledPlan, opts] = parseOptions(varargin{:});
    results = cell(1, numel(compiledPlan.Groups));
    for k = 1:numel(compiledPlan.Groups)
        group = compiledPlan.Groups(k);
        suite = [group.Descriptors.Test];
        runner = matlab.unittest.TestRunner.withTextOutput("OutputDetail", "terse");
        results{k} = runner.run(suite);
    end
    failed = cellfun(@hasFailures, results);
    if any(failed)
        error("LabKit:TestRun:Failure", "One or more LabKit specifications failed.");
    end
    result = struct("Plan", compiledPlan, "Results", {results}, ...
        "RunName", opts.RunName, "ArtifactsRoot", opts.ArtifactsRoot);
end

function [compiledPlan, opts] = parseOptions(varargin)
    p = inputParser;
    p.FunctionName = "labkittest.run";
    p.addParameter("Plan", struct(), @isPlanOrEmpty);
    p.addParameter("RunName", "labkittest", @isTextScalar);
    p.addParameter("ArtifactsRoot", defaultArtifactsRoot(), @isTextScalar);
    p.KeepUnmatched = true;
    p.parse(varargin{:});
    opts = p.Results;
    if ~isempty(fieldnames(opts.Plan))
        if ~isempty(fieldnames(p.Unmatched))
            error("LabKit:TestRun:PlanWithSelectors", ...
                "A compiled Plan cannot be combined with selectors.");
        end
        compiledPlan = opts.Plan;
    else
        selectorArgs = unmatchedPairs(p.Unmatched);
        compiledPlan = labkittest.plan(selectorArgs{:});
    end
    opts.RunName = string(opts.RunName);
    opts.ArtifactsRoot = string(opts.ArtifactsRoot);
end

function pairs = unmatchedPairs(values)
    names = fieldnames(values);
    pairs = cell(1, 2 * numel(names));
    for k = 1:numel(names)
        pairs{2 * k - 1} = names{k};
        pairs{2 * k} = values.(names{k});
    end
end

function tf = isPlanOrEmpty(value)
    tf = isstruct(value) && (isempty(fieldnames(value)) || ...
        all(isfield(value, {"Descriptors", "Groups", "Reasons", "Fallback", "ManualChecks"})));
end

function tf = isTextScalar(value)
    tf = ischar(value) || (isstring(value) && isscalar(value));
end

function root = defaultArtifactsRoot()
    packageFolder = fileparts(mfilename("fullpath"));
    root = fullfile(fileparts(fileparts(packageFolder)), "artifacts", "runs");
end

function tf = hasFailures(results)
    tf = any([results.Failed]) || any([results.Incomplete]);
end
