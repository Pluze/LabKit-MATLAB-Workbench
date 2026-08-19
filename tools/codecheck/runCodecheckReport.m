function report = runCodecheckReport(root, varargin)
%RUNCODECHECKREPORT Run MATLAB code and compatibility analysis.
%
% Syntax:
%   report = runCodecheckReport(root)
%   report = runCodecheckReport(root, "OpenReport", false)
%   report = runCodecheckReport(root, "ProgressFcn", progressFcn)
%
% Inputs:
%   root - LabKit checkout folder as a character vector or string scalar.
%
% Name-Value Options:
%   OpenReport - Logical scalar controlling whether the generated HTML opens
%       in the system browser. Default is true.
%   ProgressFcn - Empty or a function handle called as fcn(message, value),
%       where value is a scalar between zero and one. Default writes progress
%       to the command window.
%
% Outputs:
%   report - Scalar struct describing the generated artifacts and counts.
%       jsonFile and compatibilityJsonFile contain the native Code Analyzer
%       and CodeCompatibilityAnalysis data. htmlFile combines both analyses.
%       fileCount, issueCount, suppressedIssueCount,
%       compatibilityCheckCount, and compatibilityRecommendationCount report
%       the corresponding result sizes.
%
% Errors:
%   Analyzer, file-access, and report-write failures propagate to the caller.
%   Invalid inputs are rejected by inputParser.
%
% Example:
%   report = runCodecheckReport(pwd, "OpenReport", false);
%
% See also codeIssues, analyzeCodeCompatibility, codeCompatibilityReport

    p = inputParser;
    p.addRequired("root", @isTextScalar);
    p.addParameter("ProgressFcn", [], @(value) isempty(value) || isa(value, "function_handle"));
    p.addParameter("OpenReport", true, @islogicalScalar);
    p.parse(root, varargin{:});

    root = char(string(p.Results.root));
    progressFcn = p.Results.ProgressFcn;
    if isempty(progressFcn)
        progressFcn = @writeConsoleProgress;
    end
    excludedFolders = [".git", ".github", ".vscode", ".codes", ...
        "artifacts", "node_modules", "photos"];
    scanRoots = codecheckScanRoots(root);

    notifyProgress(progressFcn, "Finding MATLAB files...", 0.02);
    filesByRoot = cell(numel(scanRoots), 1);
    for k = 1:numel(scanRoots)
        filesByRoot{k} = collectFiles(scanRoots(k), "*.m", excludedFolders);
    end
    files = [filesByRoot{:}];
    files = sort(unique(files, "stable"));
    notifyProgress(progressFcn, ...
        sprintf("Running codeIssues on %d MATLAB file(s)...", numel(files)), ...
        0.08);
    issues = codeIssues(files(:));
    notifyProgress(progressFcn, ...
        sprintf("Running Code Compatibility Analyzer on %d MATLAB file(s)...", ...
        numel(files)), 0.48);
    compatibility = analyzeCodeCompatibility(files(:));

    outputRoot = fullfile(root, "artifacts", "code-check");
    reportBase = uniqueReportBase(outputRoot);
    output = reportBase + ".json";
    notifyProgress(progressFcn, "Writing native codeIssues report...", 0.92);
    ensureFolder(fileparts(output));
    sourceRoot = commonSourceRoot([string(root), files]);
    exportCodeIssuesJson(issues, output, sourceRoot);

    compatibilityOutput = reportBase + "_compatibility.json";
    notifyProgress(progressFcn, ...
        "Writing CodeCompatibilityAnalysis report...", 0.95);
    exportCodeCompatibilityJson(compatibility, compatibilityOutput);

    notifyProgress(progressFcn, "Writing combined code analysis HTML report...", 0.98);
    htmlOutput = reportBase + ".html";
    writeCodecheckReport(output, compatibilityOutput, htmlOutput);
    if p.Results.OpenReport
        openHtmlReport(htmlOutput);
    end

    report = struct();
    report.jsonFile = string(output);
    report.compatibilityJsonFile = string(compatibilityOutput);
    report.htmlFile = string(htmlOutput);
    report.fileCount = numel(files);
    report.issueCount = height(issues.Issues);
    report.suppressedIssueCount = height(issues.SuppressedIssues);
    report.compatibilityCheckCount = height(compatibility.ChecksPerformed);
    report.compatibilityRecommendationCount = ...
        height(compatibility.Recommendations);
    notifyProgress(progressFcn, "Code analysis report complete.", 1.00);
end

function exportCodeIssuesJson(issues, output, sourceRoot)
    if ismethod(issues, "export")
        export(issues, output, "FileFormat", "json", ...
            "SourceRoot", sourceRoot);
        return;
    end

    % R2022b exposes the same public codeIssues properties but predates the
    % codeIssues.export method. jsonencode preserves that native property
    % schema for the report reader without resolving an unrelated export
    % function from the MATLAB path.
    fid = fopen(output, "w", "n", "UTF-8");
    if fid < 0
        error("LabKit:Codecheck:WriteFailed", ...
            "Could not write Code Analyzer JSON report: %s", output);
    end
    cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, "%s\n", jsonencode(issues));
    clear cleanup
end

function exportCodeCompatibilityJson(analysis, output)
    payload = struct();
    payload.Date = analysis.Date;
    payload.MATLABVersion = analysis.MATLABVersion;
    payload.Files = analysis.Files;
    payload.ChecksPerformed = table2struct(analysis.ChecksPerformed);
    payload.Recommendations = table2struct(analysis.Recommendations);
    writeJson(output, payload, "Code Compatibility Analysis");
end

function writeJson(output, payload, label)
    fid = fopen(output, "w", "n", "UTF-8");
    if fid < 0
        error("LabKit:Codecheck:WriteFailed", ...
            "Could not write %s JSON report: %s", label, output);
    end
    cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, "%s\n", jsonencode(payload));
    clear cleanup
end

function reportBase = uniqueReportBase(outputRoot)
    ensureFolder(outputRoot);
    stamp = string(datetime("now", "Format", "yyyyMMdd_HHmmss"));
    reportBase = fullfile(outputRoot, "matlab_code_issues_" + string(stamp));
    suffix = 1;
    while exist(reportBase + ".json", "file") == 2 || ...
            exist(reportBase + "_compatibility.json", "file") == 2 || ...
            exist(reportBase + ".html", "file") == 2
        reportBase = fullfile(outputRoot, ...
            "matlab_code_issues_" + string(stamp) + "_" + string(suffix));
        suffix = suffix + 1;
    end
end

function openHtmlReport(htmlOutput)
    try
        web(htmlOutput, "-browser");
    catch
    end
end

function sourceRoot = commonSourceRoot(paths)
    paths = string(paths);
    paths = paths(strlength(paths) > 0);
    if isempty(paths)
        sourceRoot = pwd;
        return;
    end

    folders = strings(numel(paths), 1);
    for k = 1:numel(paths)
        if isfolder(paths(k))
            folders(k) = paths(k);
        else
            folders(k) = string(fileparts(char(paths(k))));
        end
    end

    splitFolders = cell(numel(folders), 1);
    for k = 1:numel(folders)
        splitFolders{k} = splitPathParts(folders(k));
    end

    common = splitFolders{1};
    for k = 2:numel(splitFolders)
        common = commonPrefix(common, splitFolders{k});
    end
    if isempty(common)
        sourceRoot = filesep;
    else
        sourceRoot = fullfile(common{:});
        if startsWith(char(folders(1)), filesep)
            sourceRoot = [filesep sourceRoot];
        end
    end
end

function parts = splitPathParts(pathValue)
    text = char(strrep(string(pathValue), "\", filesep));
    parts = strsplit(text, filesep);
    parts = parts(~cellfun("isempty", parts));
end

function prefix = commonPrefix(left, right)
    n = min(numel(left), numel(right));
    keep = false(1, n);
    for k = 1:n
        keep(k) = strcmp(left{k}, right{k});
    end
    firstMismatch = find(~keep, 1, "first");
    if isempty(firstMismatch)
        prefix = left(1:n);
    else
        prefix = left(1:firstMismatch-1);
    end
end

function roots = codecheckScanRoots(root)
    roots = string(root);
    privateRoots = acceptedPrivateAppRoots(root);
    roots = unique([roots; privateRoots], "stable");
end

function roots = acceptedPrivateAppRoots(root)
    candidates = configuredPrivateAppRoots(root);
    if forcePrivateAppGuardsEnabled()
        roots = candidates;
        return;
    end

    roots = strings(numel(candidates), 1);
    rootCount = 0;
    for k = 1:numel(candidates)
        if privateRootAcceptsMainGuardrails(candidates(k))
            rootCount = rootCount + 1;
            roots(rootCount, 1) = candidates(k);
        end
    end
    roots = roots(1:rootCount);
end

function tf = forcePrivateAppGuardsEnabled()
    value = lower(strtrim(string(getenv("LABKIT_GUARD_PRIVATE_APPS"))));
    tf = any(value == ["1", "true", "yes", "on"]);
end

function roots = configuredPrivateAppRoots(root)
    candidateRoots = strings(numel(strsplit(char(string(getenv( ...
        "LABKIT_PRIVATE_APP_ROOTS"))), pathsep)) + 1, 1);
    candidateCount = 0;
    localPrivateRoot = string(fullfile(root, "private_apps", "apps"));
    if exist(localPrivateRoot, "dir") == 7
        candidateCount = candidateCount + 1;
        candidateRoots(candidateCount) = localPrivateRoot;
    end

    envValue = string(getenv("LABKIT_PRIVATE_APP_ROOTS"));
    if strlength(strtrim(envValue)) > 0
        parts = string(strsplit(char(envValue), pathsep));
        parts = strip(parts);
        parts = parts(strlength(parts) > 0);
        for k = 1:numel(parts)
            candidate = privateAppRootAppsFolder(parts(k));
            if exist(candidate, "dir") == 7
                candidateCount = candidateCount + 1;
                candidateRoots(candidateCount) = candidate;
            end
        end
    end
    roots = unique(candidateRoots(1:candidateCount), "stable");
end

function appRoot = privateAppRootAppsFolder(root)
    root = string(root);
    if endsWith(strrep(root, "\", "/"), "/apps")
        appRoot = root;
    else
        appRoot = string(fullfile(root, "apps"));
    end
end

function tf = privateRootAcceptsMainGuardrails(appRoot)
    workspaceRoot = privateWorkspaceRoot(appRoot);
    tf = isfile(fullfile(workspaceRoot, ".labkit-accept-main-guardrails"));
end

function root = privateWorkspaceRoot(appRoot)
    appRoot = string(appRoot);
    if endsWith(strrep(appRoot, "\", "/"), "/apps")
        root = string(fileparts(char(appRoot)));
    else
        root = appRoot;
    end
end

function files = collectFiles(root, pattern, excludedFolders)
    entries = dir(fullfile(root, "**", pattern));
    files = strings(1, numel(entries));
    fileCount = 0;
    for k = 1:numel(entries)
        if entries(k).isdir
            continue;
        end
        filepath = string(fullfile(entries(k).folder, entries(k).name));
        rel = relativePath(root, filepath);
        parts = split(strrep(rel, filesep, "/"), "/");
        if any(ismember(parts, excludedFolders))
            continue;
        end
        fileCount = fileCount + 1;
        files(fileCount) = filepath;
    end
    files = files(1:fileCount);
end

function rel = relativePath(root, filepath)
    rel = char(filepath);
    prefix = [char(root) filesep];
    if startsWith(rel, prefix)
        rel = extractAfter(rel, strlength(prefix));
    end
    rel = string(rel);
end

function notifyProgress(progressFcn, message, value)
    progressFcn(message, value);
end

function writeConsoleProgress(message, value)
    fprintf("CODECHECK [%3.0f%%] %s\n", 100 * value, message);
end

function ensureFolder(folder)
    if strlength(string(folder)) > 0 && exist(folder, "dir") ~= 7
        mkdir(folder);
    end
end

function tf = isTextScalar(value)
    tf = (ischar(value) && (isrow(value) || isempty(value))) || ...
        (isstring(value) && isscalar(value));
end

function tf = islogicalScalar(value)
    tf = islogical(value) && isscalar(value);
end
