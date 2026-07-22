function targets = labkitNormalizeSuiteTargets(targets)
%LABKITNORMALIZESUITETARGETS Normalize test-folder selectors.
% Expected caller: runLabKitTests and selector discovery. Inputs may use a
% tests/cases prefix while preserving an explicit kind prefix (unit, contract,
% or gui). Outputs are slash-separated physical or semantic folder selectors.
% Test .m files are rejected;
% use Files for paths or Tests for class and method names.

    targets = normalizeTextList(targets);
    prefixes = "tests/cases/";
    for k = 1:numel(targets)
        target = replace(strip(targets(k)), "\", "/");
        while startsWith(target, "./")
            target = extractAfter(target, 2);
        end
        for iPrefix = 1:numel(prefixes)
            if startsWith(target, prefixes(iPrefix))
                target = extractAfter(target, strlength(prefixes(iPrefix)));
                break;
            end
        end
        target = strip(target, "/");
        if endsWith(lower(target), ".m")
            error("LabKit:Tests:SuiteSelectorIsFile", ...
                "Suites selects test folders, not .m files. " + ...
                "Use Files for paths or Tests for names: %s", target);
        end
        targets(k) = target;
    end
    targets = targets(strlength(targets) > 0);
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
