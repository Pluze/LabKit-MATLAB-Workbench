function plan = labkitInternalShardPlan(taskName, testCount)
%LABKITINTERNALSHARDPLAN Choose local process isolation for broad test gates.
% Expected caller: buildfile runWithInternalShards.
% Inputs:
%   taskName task catalog name, currently headless or gui
%   testCount finite nonnegative number of selected official tests
% Output:
%   plan struct with Count, RunInParallel, and ExecutionLabel
% Side effects: none. GUI shards are sequential because their purpose is
% process isolation from accumulated graphics state, not concurrent speedup.

    taskName = string(taskName);
    testCount = double(testCount);
    if ~isscalar(taskName) || ~isscalar(testCount) || ...
            ~isfinite(testCount) || testCount < 0
        error("LabKit:Tests:InvalidShardPlan", ...
            "Task name and test count must be valid scalars.");
    end

    if taskName == "headless"
        count = headlessShardCount(testCount);
        runInParallel = count > 1;
    elseif taskName == "gui"
        count = guiShardCount(testCount);
        runInParallel = false;
    else
        count = 1;
        runInParallel = false;
    end

    if runInParallel
        executionLabel = "parallel";
    else
        executionLabel = "sequential";
    end
    plan = struct("Count", count, "RunInParallel", runInParallel, ...
        "ExecutionLabel", executionLabel);
end

function count = guiShardCount(testCount)
    if testCount >= 60
        count = 4;
    elseif testCount >= 30
        count = 2;
    else
        count = 1;
    end
end

function count = headlessShardCount(testCount)
    if testCount >= 300
        count = 3;
    elseif testCount >= 80
        count = 2;
    else
        count = 1;
    end
end
