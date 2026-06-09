%RUN_MATLAB_CODE_CHECK Write an ignored MATLAB Code Analyzer report.
% Expected caller: manual shell/MATLAB invocation from this repository.
% Output shape: root-level JSON report file.
% Side effects: writes matlab_code_check.json.

root = fileparts(fileparts(mfilename('fullpath')));
if strlength(string(root)) == 0
    root = pwd;
end

jsonPath = fullfile(root, "matlab_code_check.json");

files = collectMFiles(root);
report = analyzeFiles(root, files);
writeJsonReport(jsonPath, report);

fprintf('Scanned %d MATLAB files.\n', report.summary.filesScanned);
fprintf('Code Analyzer messages: %d across %d files.\n', ...
    report.summary.messageCount, report.summary.filesWithMessages);
fprintf('Scan errors: %d.\n', report.summary.scanErrorCount);
fprintf('JSON report: %s\n', jsonPath);

function files = collectMFiles(root)
    entries = dir(fullfile(root, "**", "*.m"));
    files = strings(1, 0);
    for k = 1:numel(entries)
        if entries(k).isdir
            continue;
        end

        filepath = string(fullfile(entries(k).folder, entries(k).name));
        if isExcludedPath(root, filepath)
            continue;
        end

        files(end+1) = filepath;
    end
    files = sort(files);
end

function tf = isExcludedPath(root, filepath)
    excludedFolders = [".git", ".github", ".vscode", ".codes", ...
        "artifacts", "node_modules", "photos"];
    rel = relativePath(root, filepath);
    parts = split(rel, "/");
    tf = any(ismember(parts, excludedFolders));
end

function report = analyzeFiles(root, files)
    fileReports = emptyFileReport();
    scanErrors = emptyScanError();

    for k = 1:numel(files)
        filepath = files(k);
        rel = relativePath(root, filepath);
        lineText = readFileLines(filepath);

        try
            rawMessages = checkcode(char(filepath), "-id");
        catch err
            scanErrors(end+1) = struct( ...
                "path", rel, ...
                "absolutePath", filepath, ...
                "identifier", string(err.identifier), ...
                "message", string(err.message));
            rawMessages = struct([]);
        end

        messages = normalizeMessages(rel, filepath, rawMessages, lineText);
        if ~isempty(messages)
            fileReports(end+1) = struct( ...
                "path", rel, ...
                "absolutePath", filepath, ...
                "messageCount", numel(messages), ...
                "messages", messages);
        end
    end

    filesWithMessages = numel(fileReports);
    messageCount = sum(arrayfun(@(item) item.messageCount, fileReports));
    report = struct();
    report.schemaVersion = "1.1";
    report.generatedAt = string(datetime("now", "TimeZone", "local", ...
        "Format", "yyyy-MM-dd'T'HH:mm:ssXXX"));
    report.generator = "scripts/run_matlab_code_check.m";
    report.root = string(root);
    report.outputs = struct( ...
        "json", "matlab_code_check.json");
    report.scope = struct( ...
        "description", "All .m files under the repository except generated, hidden, photo, and dependency folders.", ...
        "excludedFolders", [".git", ".github", ".vscode", ".codes", ...
            "artifacts", "node_modules", "photos"]);
    report.summary = struct( ...
        "filesScanned", numel(files), ...
        "filesWithMessages", filesWithMessages, ...
        "messageCount", messageCount, ...
        "scanErrorCount", numel(scanErrors));
    report.files = fileReports;
    report.scanErrors = scanErrors;
end

function messages = normalizeMessages(rel, filepath, rawMessages, lineText)
    messages = emptyMessage();
    for k = 1:numel(rawMessages)
        raw = rawMessages(k);
        line = numericVectorField(raw, "line");
        column = numericVectorField(raw, "column");
        message = stringField(raw, "message");
        identifier = analyzerId(raw, message);
        fix = fixText(raw);
        primaryLine = firstNumeric(line);
        if primaryLine >= 1 && primaryLine <= numel(lineText)
            sourceLine = string(strtrim(lineText(primaryLine)));
        else
            sourceLine = "";
        end

        messages(end+1) = struct( ...
            "path", rel, ...
            "absolutePath", filepath, ...
            "line", line, ...
            "column", column, ...
            "id", identifier, ...
            "message", message, ...
            "fix", fix, ...
            "sourceLine", sourceLine);
    end
end

function id = analyzerId(raw, message)
    id = stringField(raw, "id");
    if strlength(id) > 0
        return;
    end

    tokens = regexp(char(message), "\(([^()]+)\)\s*$", "tokens", "once");
    if ~isempty(tokens)
        id = string(tokens{1});
    end
end

function value = numericVectorField(raw, name)
    if isfield(raw, name) && ~isempty(raw.(name))
        value = double(raw.(name));
    else
        value = NaN;
    end
end

function value = firstNumeric(values)
    values = values(~isnan(values));
    if isempty(values)
        value = NaN;
    else
        value = values(1);
    end
end

function value = stringField(raw, name)
    if isfield(raw, name) && ~isempty(raw.(name))
        value = string(raw.(name));
    else
        value = "";
    end
end

function value = fixText(raw)
    value = "";
    if ~isfield(raw, "fix") || isempty(raw.fix)
        return;
    end
    if ischar(raw.fix) || isstring(raw.fix)
        value = string(raw.fix);
    end
end

function lines = readFileLines(filepath)
    try
        lines = readlines(filepath);
    catch
        text = string(fileread(filepath));
        lines = splitlines(text);
    end
end

function writeJsonReport(filepath, report)
    try
        text = jsonencode(report, PrettyPrint=true);
    catch
        text = jsonencode(report);
    end
    fid = fopen(filepath, "w");
    assert(fid > 0, "Could not open JSON report for writing: %s", filepath);
    cleaner = onCleanup(@() fclose(fid));
    fprintf(fid, "%s\n", text);
    clear cleaner;
end

function rel = relativePath(root, filepath)
    rootPrefix = string(root) + string(filesep);
    rel = string(filepath);
    if startsWith(rel, rootPrefix)
        rel = extractAfter(rel, strlength(rootPrefix));
    end
    rel = strrep(rel, filesep, "/");
end

function value = emptyFileReport()
    value = repmat(struct( ...
        "path", "", ...
        "absolutePath", "", ...
        "messageCount", 0, ...
        "messages", emptyMessage()), 1, 0);
end

function value = emptyMessage()
    value = repmat(struct( ...
        "path", "", ...
        "absolutePath", "", ...
        "line", NaN, ...
        "column", NaN, ...
        "id", "", ...
        "message", "", ...
        "fix", "", ...
        "sourceLine", ""), 1, 0);
end

function value = emptyScanError()
    value = repmat(struct( ...
        "path", "", ...
        "absolutePath", "", ...
        "identifier", "", ...
        "message", ""), 1, 0);
end
