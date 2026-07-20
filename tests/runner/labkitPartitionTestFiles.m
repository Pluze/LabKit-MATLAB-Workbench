function partitions = labkitPartitionTestFiles(root, testNames, shardCount)
%LABKITPARTITIONTESTFILES Assign complete test classes to worker file sets.
% Expected caller: buildfile after one official discovery probe.
% Inputs:
%   root       repository root
%   testNames  canonical ClassName/methodName values from the probe
%   shardCount positive worker count
% Output:
%   partitions struct row with Files and TestCount per worker
% Side effects: reads the tests/cases file tree. A class must have exactly one
% owning file so workers can discover only their assigned classes.

    root = string(root);
    testNames = string(testNames);
    testNames = testNames(:).';
    if ~isscalar(root) || strlength(root) == 0 || ...
            ~isnumeric(shardCount) || ~isscalar(shardCount) || ...
            ~isfinite(shardCount) || shardCount < 1 || ...
            shardCount ~= fix(shardCount)
        error("LabKit:Tests:InvalidFilePartition", ...
            "File partitioning requires one root and a positive shard count.");
    end

    classNames = extractBefore(testNames + "/", "/");
    [classes, ~, classIndex] = unique(classNames, "stable");
    weights = accumarray(classIndex(:), 1, [numel(classes), 1]).';
    files = owningFiles(root, classes);
    orderTable = table(classes(:), files(:), weights(:), ...
        'VariableNames', {'Class', 'File', 'Weight'});
    orderTable = sortrows(orderTable, {'Weight', 'Class'}, ...
        {'descend', 'ascend'});

    partitions = repmat(struct( ...
        "Files", strings(1, 0), "TestCount", 0), 1, shardCount);
    loads = zeros(1, shardCount);
    for k = 1:height(orderTable)
        [~, shard] = min(loads);
        partitions(shard).Files(end + 1) = orderTable.File(k);
        partitions(shard).TestCount = ...
            partitions(shard).TestCount + orderTable.Weight(k);
        loads(shard) = partitions(shard).TestCount;
    end
end

function files = owningFiles(root, classes)
    casesRoot = fullfile(root, "tests", "cases");
    entries = dir(fullfile(casesRoot, "**", "*.m"));
    entryClasses = erase(string({entries.name}), ".m");
    files = strings(size(classes));
    for k = 1:numel(classes)
        matches = find(entryClasses == classes(k));
        if isempty(matches)
            error("LabKit:Tests:TestOwnerNotFound", ...
                "No tests/cases file owns class %s.", classes(k));
        end
        if numel(matches) > 1
            error("LabKit:Tests:AmbiguousTestOwner", ...
                "Multiple tests/cases files own class %s.", classes(k));
        end
        files(k) = string(fullfile( ...
            entries(matches).folder, entries(matches).name));
    end
end
