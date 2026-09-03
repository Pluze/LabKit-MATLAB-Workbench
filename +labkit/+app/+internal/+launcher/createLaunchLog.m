function log = createLaunchLog(root)
%CREATELAUNCHLOG Create one bounded, path-sanitized Launcher event log.
% Expected caller: createLauncher. ROOT receives ignored diagnostic output.
% Logging failure returns an unavailable log and never blocks the Launcher.

log = struct("file", "", "clock", tic);
try
    folder = fullfile(root, "artifacts", "logs", "launcher");
    if exist(folder, "dir") ~= 7
        mkdir(folder);
    end
    stamp = string(datetime("now", "TimeZone", "UTC", ...
        "Format", "yyyyMMdd-HHmmss-SSS"));
    filepath = fullfile(folder, "launcher-" + stamp + ".jsonl");
    fid = fopen(filepath, "w", "n", "UTF-8");
    if fid < 0
        return;
    end
    fclose(fid);
    log.file = string(filepath);
    retainRecentLogs(folder, log.file);
catch
    log.file = "";
end
end

function retainRecentLogs(folder, currentFile)
maximumLogs = 20;
entries = dir(fullfile(folder, "launcher-*.jsonl"));
if numel(entries) <= maximumLogs
    return;
end
[~, order] = sort([entries.datenum], "descend");
entries = entries(order);
for k = maximumLogs + 1:numel(entries)
    filepath = string(fullfile(entries(k).folder, entries(k).name));
    if filepath ~= currentFile && isfile(filepath)
        try
            delete(filepath);
        catch
            % Retention failure must not prevent Launcher use.
        end
    end
end
end
