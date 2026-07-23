function [tests, fallback] = labkitAppSmokeFeatureTests(root, requiredFeatures)
%LABKITAPPSMOKEFEATURETESTS Select the smallest deterministic App smoke set.
% Expected caller: changed-file validation planner.
% Inputs:
%   root             repository root
%   requiredFeatures route-feature names, with or without the RouteFeature: prefix
% Outputs:
%   tests            smoke test-class selectors covering every required feature
%   fallback         true when metadata cannot prove the requested coverage
% Side effects: reads current smoke-test source files.

    requiredFeatures = normalizeFeatures(requiredFeatures);
    candidates = smokeCandidates(root);
    if isempty(candidates)
        error("LabKit:Tests:MissingAppSmokeCoverage", ...
            "No App smoke tests are available for downstream framework routing.");
    end

    allFeatures = [candidates.Features];
    if ~all(ismember(requiredFeatures, allFeatures))
        tests = string({candidates.Name});
        fallback = true;
        return;
    end

    remaining = requiredFeatures;
    tests = strings(1, 0);
    while ~isempty(remaining)
        coverage = zeros(1, numel(candidates));
        for k = 1:numel(candidates)
            coverage(k) = sum(ismember(remaining, candidates(k).Features));
        end
        [bestCoverage, best] = max(coverage);
        if bestCoverage == 0
            tests = string({candidates.Name});
            fallback = true;
            return;
        end
        tests(end + 1) = candidates(best).Name;
        remaining = setdiff(remaining, candidates(best).Features, "stable");
        candidates(best).Features = strings(1, 0);
    end
    fallback = false;
end

function candidates = smokeCandidates(root)
    entries = dir(fullfile(root, "tests", "cases", "gui", "apps", ...
        "**", "smoke", "*Test.m"));
    candidates = repmat(struct("Name", "", "Features", strings(1, 0)), ...
        1, numel(entries));
    for k = 1:numel(entries)
        [~, name] = fileparts(entries(k).name);
        source = string(fileread(fullfile(entries(k).folder, entries(k).name)));
        tokens = regexp(source, "'RouteFeature:([^']+)'", "tokens");
        features = strings(1, numel(tokens));
        for t = 1:numel(tokens)
            features(t) = "RouteFeature:" + string(tokens{t}{1});
        end
        candidates(k) = struct( ...
            "Name", string(name), ...
            "Features", unique(features, "stable"));
    end
    [~, order] = sort(string({candidates.Name}));
    candidates = candidates(order);
end

function features = normalizeFeatures(features)
    features = string(features);
    features = features(:).';
    features = features(strlength(features) > 0);
    for k = 1:numel(features)
        if startsWith(lower(features(k)), "routefeature:")
            features(k) = "RouteFeature:" + extractAfter(features(k), ...
                strlength("routefeature:"));
        end
    end
    needsPrefix = ~startsWith(features, "RouteFeature:");
    features(needsPrefix) = "RouteFeature:" + features(needsPrefix);
    features = unique(features, "stable");
end
