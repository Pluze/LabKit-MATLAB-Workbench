function handled = labkitRunInternalShards(root, spec, args)
%LABKITRUNINTERNALSHARDS Run broad local build tasks in child MATLAB workers.
% Expected caller: buildfile.m after resolving one task catalog entry.
% Inputs:
%   root repository root
%   spec task catalog entry
%   args parsed runner name/value arguments for the task
% Output:
%   handled true when this function ran the selected task in child workers
% Side effects: starts child MATLAB processes and writes ignored artifacts.
% GitHub Actions remains single-process because concurrent license behavior
% is not established there. Local macOS, Linux, and Windows use Java's
% platform-neutral ProcessBuilder rather than generated shell scripts.

    handled = false;
    if ~any(spec.Name == ["headless", "gui"]) || ...
            isInternalShardWorker() || isGitHubActions()
        return;
    end

    addpath(fullfile(root, "tests"));
    probe = runLabKitTests(args{:}, ...
        "ListOnly", true, ...
        "PrintList", false, ...
        "FailIfNoTests", false, ...
        "RunName", spec.Name + "_probe", ...
        "ArtifactsRoot", fullfile(root, "artifacts"));

    shardPlan = labkitInternalShardPlan(spec.Name, probe.count);
    if shardPlan.Count <= 1
        return;
    end
    if ~usejava("jvm")
        error("LabKit:Build:ShardProcessRuntime", ...
            "Local internal sharding requires MATLAB's Java runtime.");
    end

    fprintf(['LabKit shard probe: %d test(s) matched; running %d ' ...
        'internal %s shard(s).\n'], probe.count, shardPlan.Count, ...
        shardPlan.ExecutionLabel);
    partitions = labkitPartitionTestFiles( ...
        root, probe.tests.Name, shardPlan.Count);
    runWorkers(root, spec.Name, args, partitions, ...
        shardPlan.RunInParallel);
    handled = true;
end

function tf = isInternalShardWorker()
    tf = string(getenv("LABKIT_INTERNAL_SHARD_WORKER")) == "1";
end

function tf = isGitHubActions()
    tf = string(getenv("GITHUB_ACTIONS")) == "true";
end

function runWorkers(root, runName, args, partitions, runInParallel)
    shardCount = numel(partitions);
    logsRoot = fullfile(root, "artifacts", "logs", runName + "-orchestrator");
    ensureFolder(logsRoot);
    workers = repmat(emptyWorker(), 1, shardCount);

    if runInParallel
        try
            for k = 1:shardCount
                workers(k) = startWorker( ...
                    root, runName, args, partitions(k), logsRoot, k - 1);
            end
        catch exception
            terminateWorkers(workers);
            rethrow(exception);
        end
        cleanup = onCleanup(@() terminateWorkers(workers));
        monitorWorkers(workers);
        verifyWorkers(workers);
        clear cleanup
    else
        for k = 1:shardCount
            worker = startWorker( ...
                root, runName, args, partitions(k), logsRoot, k - 1);
            cleanup = onCleanup(@() terminateWorkers(worker));
            monitorWorkers(worker);
            verifyWorkers(worker);
            clear cleanup
        end
    end
end

function worker = emptyWorker()
    worker = struct( ...
        "Index", 0, ...
        "Name", "", ...
        "LogFile", "", ...
        "StatusFile", "", ...
        "Process", []);
end

function worker = startWorker( ...
        root, runName, args, partition, logsRoot, shardIndex)
    shardName = string(sprintf("%s-shard-%d", runName, shardIndex));
    workerLog = string(fullfile(logsRoot, shardName + ".log"));
    statusFolder = fullfile(root, "artifacts", "logs", shardName);
    statusFile = string(fullfile(statusFolder, "active-test.txt"));
    clearActiveStatus(statusFolder);

    batch = shardBatchCommand( ...
        root, args, shardName, partition.Files);
    command = processCommand(batch);
    builder = javaObject("java.lang.ProcessBuilder", javaStringArray(command));
    builder.redirectErrorStream(true);
    builder.redirectOutput(java.io.File(char(workerLog)));
    environment = builder.environment();
    environment.put("LABKIT_INTERNAL_SHARD_WORKER", "1");

    worker = struct( ...
        "Index", shardIndex, ...
        "Name", shardName, ...
        "LogFile", workerLog, ...
        "StatusFile", statusFile, ...
        "Process", builder.start());
end

function command = processCommand(batch)
    executable = "matlab";
    if ispc
        executable = "matlab.exe";
    end
    command = [ ...
        string(fullfile(matlabroot, "bin", executable)), ...
        "-batch", ...
        string(batch)];
end

function values = javaStringArray(command)
    command = string(command);
    values = javaArray("java.lang.String", numel(command));
    for k = 1:numel(command)
        values(k) = java.lang.String(char(command(k)));
    end
end

function monitorWorkers(workers)
    reportTimer = tic;
    while anyWorkersAlive(workers)
        pause(0.25);
        if toc(reportTimer) >= 15
            printWorkerStatus(workers);
            reportTimer = tic;
        end
    end
    printWorkerStatus(workers);
end

function tf = anyWorkersAlive(workers)
    tf = false;
    for k = 1:numel(workers)
        if workers(k).Process.isAlive()
            tf = true;
            return;
        end
    end
end

function printWorkerStatus(workers)
    fprintf("LabKit internal shard status:\n");
    for k = 1:numel(workers)
        worker = workers(k);
        if isfile(worker.StatusFile)
            summary = strip(string(fileread(worker.StatusFile)));
        elseif worker.Process.isAlive()
            summary = "STARTING worker process";
        else
            summary = "EXITED before publishing status";
        end
        fprintf("  shard %d: %s\n", worker.Index, summary);
    end
end

function verifyWorkers(workers)
    failures = false(1, numel(workers));
    for k = 1:numel(workers)
        failures(k) = workers(k).Process.waitFor() ~= 0;
    end
    for k = find(failures)
        fprintf(2, "LabKit shard %d failed; log follows:\n", ...
            workers(k).Index);
        if isfile(workers(k).LogFile)
            fprintf(2, "%s", fileread(workers(k).LogFile));
        else
            fprintf(2, "Worker log was not created: %s\n", ...
                workers(k).LogFile);
        end
    end
    if any(failures)
        error("LabKit:Build:ShardFailure", ...
            "One or more internal test shards failed. Logs: %s", ...
            fileparts(workers(1).LogFile));
    end
end

function terminateWorkers(workers)
    for k = 1:numel(workers)
        process = workers(k).Process;
        if ~isempty(process) && process.isAlive()
            process.destroy();
        end
    end
end

function clearActiveStatus(logFolder)
    files = [ ...
        string(fullfile(logFolder, "active-test.json")), ...
        string(fullfile(logFolder, "active-test.txt"))];
    for k = 1:numel(files)
        if isfile(files(k))
            delete(files(k));
        end
    end
end

function batch = shardBatchCommand(root, args, runName, files)
    workerArgs = selectionArgsWithFiles(args, files);
    shardArgs = [workerArgs, { ...
        "RunName", string(runName), ...
        "ArtifactsRoot", fullfile(root, "artifacts")}];
    batch = "addpath(" + matlabLiteral(fullfile(root, "tests")) + "); " + ...
        "runLabKitTests(" + matlabArgumentList(shardArgs) + ");";
end

function args = selectionArgsWithFiles(args, files)
    names = string(args(1:2:end));
    keepPairs = ~ismember(names, ["Suites", "Files"]);
    keep = repelem(keepPairs, 2);
    args = [args(keep), {"Files", files}];
end

function text = matlabArgumentList(args)
    parts = strings(1, numel(args));
    for k = 1:numel(args)
        parts(k) = matlabLiteral(args{k});
    end
    text = strjoin(parts, ", ");
end

function text = matlabLiteral(value)
    if islogical(value)
        if value
            text = "true";
        else
            text = "false";
        end
    elseif isnumeric(value)
        text = string(value);
    else
        value = string(value);
        if isscalar(value)
            text = """" + replace(value, """", """""") + """";
        else
            quoted = """" + replace(value, """", """""") + """";
            text = "[" + strjoin(quoted, ", ") + "]";
        end
    end
end

function ensureFolder(folder)
    if exist(folder, "dir") ~= 7
        mkdir(folder);
    end
end
