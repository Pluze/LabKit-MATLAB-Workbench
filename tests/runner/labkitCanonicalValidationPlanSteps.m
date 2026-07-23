function [executionSteps, summary] = labkitCanonicalValidationPlanSteps(steps, listings)
%LABKITCANONICALVALIDATIONPLANSTEPS Remove repeated tests from plan execution.
% Expected caller: runLabKitTests validation-plan execution.
% Inputs:
%   steps    validation-plan structs with Suites, Files, Tests, and IncludeGui
%   listings cell array of matching test-name tables, one per plan step
% Output:
%   executionSteps equivalent scoped selections that run each matched test once
%   summary execution and duplicate counts for human progress output
% Side effects: none.

    if numel(steps) ~= numel(listings)
        error("LabKit:Tests:InvalidPlanListing", ...
            "Validation plan steps and listings must have equal lengths.");
    end

    executionSteps = steps([]);
    canonicalNames = cell(1, 2);
    routeCounts = zeros(1, 2);
    seen = strings(1, 0);
    plannedCount = 0;
    duplicateCount = 0;
    for k = 1:numel(steps)
        names = listingNames(listings{k});
        plannedCount = plannedCount + numel(names);
        identities = lower(names) + "|" + string(steps(k).IncludeGui);
        keep = ~ismember(identities, seen);
        duplicateCount = duplicateCount + sum(~keep);
        seen = [seen, identities(keep)];
        group = 1 + double(steps(k).IncludeGui);
        canonicalNames{group} = [canonicalNames{group}, names(keep)];
        if any(keep)
            routeCounts(group) = routeCounts(group) + 1;
        end
    end

    for group = 1:2
        names = canonicalNames{group};
        if isempty(names)
            continue;
        end
        includeGui = logical(group - 1);
        source = find([steps.IncludeGui] == includeGui, 1);
        step = steps(source);
        step.RunNameSuffix = canonicalRunNameSuffix(includeGui);
        step.Suites = strings(1, 0);
        step.Files = strings(1, 0);
        step.Tests = names;
        step.IncludeGui = includeGui;
        step.Reason = "canonical " + executionKind(includeGui) + ...
            " test union from " + string(routeCounts(group)) + " semantic route(s)";
        executionSteps(end + 1) = step;
    end

    summary = struct( ...
        "plannedCount", plannedCount, ...
        "executionCount", numel(seen), ...
        "duplicateCount", duplicateCount, ...
        "stepCount", numel(executionSteps));
end

function suffix = canonicalRunNameSuffix(includeGui)
    suffix = "canonical_headless";
    if includeGui
        suffix = "canonical_gui";
    end
end

function kind = executionKind(includeGui)
    kind = "non-GUI";
    if includeGui
        kind = "hidden-GUI";
    end
end

function names = listingNames(listing)
    if ~istable(listing) || ~ismember("Name", string(listing.Properties.VariableNames))
        error("LabKit:Tests:InvalidPlanListing", ...
            "Each validation-plan listing must be a table with a Name column.");
    end
    names = string(listing.Name);
    names = names(:).';
    names = names(strlength(names) > 0);
end
