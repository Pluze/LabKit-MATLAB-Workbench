function [htmlFile, artifacts] = profileLabKitTarget(target, htmlFile, varargin)
%PROFILELABKITTARGET Profile a LabKit MATLAB target and export profiler artifacts.
%
% Expected caller: LabKit maintainers diagnosing startup, callbacks, scripts, or
% helper-function cost.
% Inputs:
%   target   function name, .m file path, function handle, or a
%            profile('info') struct. Empty target opens a file picker.
%   htmlFile optional output HTML file. Defaults under artifacts/profile/.
% Outputs:
%   htmlFile  generated HTML report path
%   artifacts struct with htmlFile, jsonFile, and functionCount
% Options:
%   OpenReport           false opens no browser; true opens the generated HTML report.
%   WaitForGuiClose      true waits for newly opened figures before export.
%   CloseFiguresAfterRun false closes newly opened figures after profiling.
%   ChangeFolder         true cd's to a resolved .m file folder while profiling.
%   OutputRoot           default artifact folder for generated reports.
%   InitialRows          initial function-table rows shown in the report.
%   ChartTopN            number of top roots to show in the flame control.
%   SortBy               initial table sort field, default SelfTime.
%   ProjectRoot          folder used to tag project-owned rows.
%   TargetFile           explicit target .m path for profile-info exports.
%   JsonFile             optional explicit full JSON sidecar path.
%   PrintSummary         true prints the TXT summary to MATLAB stdout.
%   SummaryTopN          number of rows in each agent summary table.
%   RethrowError         true rethrows target errors after exporting profile data.
%
% Examples:
%   addpath(fullfile('tools', 'profiling'))
%   profileLabKitTarget("labkit_launcher", [], "WaitForGuiClose", false, ...
%       "PrintSummary", true)
%   profileLabKitTarget("labkit_launcher", [], "OpenReport", true)

    if nargin < 1
        target = [];
    end
    if nargin < 2 || isempty(htmlFile)
        htmlFile = "";
    end

    if isempty(target)
        [fileName, folderName] = uigetfile({'*.m', 'MATLAB files (*.m)'; '*.*', 'All files (*.*)'}, ...
            'Select MATLAB GUI/function/script to profile');
        if isequal(fileName, 0)
            fprintf('profileLabKitTarget canceled: no file selected.\n');
            htmlFile = "";
            artifacts = emptyArtifacts(htmlFile);
            return;
        end
        target = fullfile(folderName, fileName);
    end

    opt = parseProfileOptions(varargin{:});
    if strlength(string(htmlFile)) == 0
        htmlFile = defaultHtmlName(target, opt.OutputRoot);
    end
    htmlFile = absoluteOutputPath(htmlFile);

    if isstruct(target) && isfield(target, 'FunctionTable')
        tagContext = makeTagContext(opt, "", "");
        payload = profileLabKitPayload(target, 'provided profile info structure', [], ...
            mfilename('fullpath'), tagContext);
        artifacts = profileLabKitWriteReport(payload, htmlFile, opt);
        htmlFile = char(artifacts.htmlFile);
        return;
    end

    targetLabel = targetLabelText(target);
    [runner, runFolder, cleanupPath, targetFile] = prepareRunner(target);

    folderCleanup = enterRunFolder(opt.ChangeFolder, runFolder);

    fprintf('\n=== profileLabKitTarget ===\n');
    fprintf('Target: %s\n', targetLabel);
    fprintf('Output: %s\n', htmlFile);
    fprintf('Starting profiler...\n');

    beforeFigs = currentFigures();
    runError = [];

    profile clear;
    profile on;
    try
        runner();
        if opt.WaitForGuiClose
            newFigs = newFigures(beforeFigs);
            if ~isempty(newFigs)
                fprintf('GUI launched. Close the GUI window(s) to finish profiling and export HTML...\n');
                waitForClose(newFigs);
            else
                fprintf('No new GUI figure/uifigure detected after the target returned. Exporting profile now.\n');
            end
        end
    catch ME
        runError = ME;
    end
    profile off;
    profInfo = profile('info');

    if opt.CloseFiguresAfterRun
        closeFigures(newFigures(beforeFigs));
    end
    delete(folderCleanup);
    if isa(cleanupPath, 'function_handle')
        cleanupPath();
    end

    tagContext = makeTagContext(opt, targetFile, runFolder);
    payload = profileLabKitPayload(profInfo, targetLabel, runError, ...
        mfilename('fullpath'), tagContext);
    artifacts = profileLabKitWriteReport(payload, htmlFile, opt);
    htmlFile = char(artifacts.htmlFile);

    if ~isempty(runError)
        fprintf(2, 'Target ended with an error, but profile data was exported.\n');
        fprintf(2, '%s\n', runError.message);
        if opt.RethrowError
            rethrow(runError);
        end
    end
end

function opt = parseProfileOptions(varargin)
    p = inputParser;
    p.FunctionName = 'profileLabKitTarget';
    addParameter(p, 'OpenReport', false, @isLogicalScalar);
    addParameter(p, 'WaitForGuiClose', true, @isLogicalScalar);
    addParameter(p, 'CloseFiguresAfterRun', false, @isLogicalScalar);
    addParameter(p, 'ChangeFolder', true, @isLogicalScalar);
    addParameter(p, 'OutputRoot', fullfile(repoRoot(), 'artifacts', 'profile'), @isTextScalar);
    addParameter(p, 'InitialRows', 500, @isPositiveScalar);
    addParameter(p, 'ChartTopN', 40, @isPositiveScalar);
    addParameter(p, 'SortBy', 'SelfTime', @isTextScalar);
    addParameter(p, 'ProjectRoot', repoRoot(), @isTextScalar);
    addParameter(p, 'TargetFile', "", @isTextScalar);
    addParameter(p, 'JsonFile', "", @isTextScalar);
    addParameter(p, 'PrintSummary', false, @isLogicalScalar);
    addParameter(p, 'SummaryTopN', 20, @isPositiveScalar);
    addParameter(p, 'RethrowError', false, @isLogicalScalar);
    parse(p, varargin{:});

    opt = p.Results;
    opt.OpenReport = logical(opt.OpenReport);
    opt.WaitForGuiClose = logical(opt.WaitForGuiClose);
    opt.CloseFiguresAfterRun = logical(opt.CloseFiguresAfterRun);
    opt.ChangeFolder = logical(opt.ChangeFolder);
    opt.PrintSummary = logical(opt.PrintSummary);
    opt.RethrowError = logical(opt.RethrowError);
    opt.InitialRows = max(20, round(double(opt.InitialRows)));
    opt.ChartTopN = max(1, round(double(opt.ChartTopN)));
    opt.SummaryTopN = max(1, round(double(opt.SummaryTopN)));
    opt.SortBy = normalizeSortField(opt.SortBy);
end

function tagContext = makeTagContext(opt, resolvedTargetFile, resolvedTargetRoot)
    targetFile = string(opt.TargetFile);
    projectRoot = string(opt.ProjectRoot);
    if strlength(targetFile) == 0 && strlength(string(resolvedTargetFile)) > 0
        targetFile = string(canonicalPath(resolvedTargetFile));
    elseif strlength(targetFile) > 0
        targetFile = string(canonicalPath(targetFile));
    end
    if strlength(projectRoot) > 0
        projectRoot = string(canonicalPath(projectRoot));
    elseif strlength(string(resolvedTargetRoot)) > 0
        projectRoot = string(canonicalPath(resolvedTargetRoot));
    end
    tagContext = struct("TargetFile", targetFile, "RepoRoot", projectRoot);
end

function [runner, runFolder, cleanupPath, targetFile] = prepareRunner(target)
    cleanupPath = [];
    runFolder = "";
    targetFile = "";
    if isa(target, 'function_handle')
        runner = target;
        return;
    end
    if isstring(target)
        target = char(target);
    end
    if ~ischar(target)
        error('profileLabKitTarget:InvalidTarget', ...
            'Target must be a .m path, function name, function handle, or profile info struct.');
    end

    target = strtrim(target);
    if isempty(target)
        error('profileLabKitTarget:InvalidTarget', 'Empty target.');
    end

    filePath = resolveMFile(target);
    if strlength(string(filePath)) > 0
        [runFolder, funcName] = fileparts(filePath);
        targetFile = filePath;
        if ~isOnPath(runFolder)
            addpath(runFolder);
            cleanupPath = @() rmpath(runFolder);
        end
        if isFunctionOrClassFile(filePath)
            runner = @() invokeResolvedFunction(funcName, filePath);
        else
            runner = @() run(filePath);
        end
        return;
    end
    error('profileLabKitTarget:UnresolvedTarget', ...
        ['String targets must resolve to one function or .m file. ' ...
        'Use a function handle for calls with arguments or setup state.']);
end

function invokeResolvedFunction(funcName, filePath)
resolved = string(which(funcName));
if strlength(resolved) == 0 || ...
        string(canonicalPath(resolved)) ~= string(canonicalPath(filePath))
    error('profileLabKitTarget:TargetResolutionChanged', ...
        'Profile target no longer resolves to the validated file: %s', funcName);
end
% Dynamic maintainer-tool boundary: the name is accepted only after it
% resolves to the exact .m file selected by prepareRunner.
feval(funcName);
end

function filePath = resolveMFile(text)
    filePath = "";
    if exist(text, 'file') == 2
        [~, ~, ext] = fileparts(text);
        if isempty(ext) || strcmpi(ext, '.m')
            resolved = which(text);
            if isempty(resolved)
                resolved = text;
            end
            filePath = canonicalPath(resolved);
        end
        return;
    end

    [folderName, baseName, ext] = fileparts(text);
    if isempty(folderName)
        if isempty(ext)
            resolved = which(baseName);
        else
            resolved = which(text);
        end
        if ~isempty(resolved) && strcmpi(fileExt(resolved), '.m')
            filePath = canonicalPath(resolved);
        end
        return;
    end

    if isempty(ext)
        candidate = fullfile(folderName, [baseName '.m']);
    else
        candidate = fullfile(folderName, [baseName ext]);
    end
    if exist(candidate, 'file') == 2
        filePath = canonicalPath(candidate);
    end
end

function tf = isFunctionOrClassFile(filePath)
    tf = false;
    fid = fopen(filePath, 'r');
    if fid < 0
        return;
    end
    cleanup = onCleanup(@() fclose(fid));
    while true
        line = fgetl(fid);
        if ~ischar(line)
            clear cleanup;
            return;
        end
        line = strtrim(line);
        if isempty(line) || startsWith(line, '%')
            continue;
        end
        tf = startsWith(line, 'function') || startsWith(line, 'classdef');
        clear cleanup;
        return;
    end
end

function figs = currentFigures()
    try
        figs = findall(groot, 'Type', 'figure');
    catch
        figs = gobjects(0);
    end
    try
        figs = figs(isvalid(figs));
    catch
    end
end

function figs = newFigures(beforeFigs)
    afterFigs = currentFigures();
    figs = gobjects(size(afterFigs));
    figureCount = 0;
    for k = 1:numel(afterFigs)
        if ~any(beforeFigs == afterFigs(k))
            figureCount = figureCount + 1;
            figs(figureCount) = afterFigs(k);
        end
    end
    figs = figs(1:figureCount);
    try
        figs = figs(isvalid(figs));
    catch
    end
end

function waitForClose(figs)
    try
        figs = figs(isvalid(figs));
    catch
    end
    while ~isempty(figs) && any(isvalid(figs))
        drawnow;
        pause(0.15);
    end
    fprintf('GUI closed. Stopping profiler and exporting report...\n');
end

function closeFigures(figs)
    for k = 1:numel(figs)
        try
            if isvalid(figs(k))
                close(figs(k));
            end
        catch
        end
    end
end

function name = defaultHtmlName(target, outputRoot)
    baseName = 'target';
    if isa(target, 'function_handle')
        baseName = regexprep(func2str(target), '\W+', '_');
    elseif ischar(target) || isstring(target)
        [~, candidate] = fileparts(char(target));
        if isempty(candidate)
            candidate = regexprep(char(target), '\W+', '_');
        end
        baseName = candidate;
    elseif isstruct(target)
        baseName = 'profile_info';
    end
    if isempty(baseName)
        baseName = 'target';
    end
    stamp = char(datetime("now", "Format", "yyyyMMdd_HHmmss"));
    name = fullfile(char(outputRoot), ['profile_' baseName '_' stamp '.html']);
end

function cleanup = enterRunFolder(changeFolder, runFolder)
    if changeFolder && strlength(string(runFolder)) > 0 && ...
            exist(runFolder, 'dir') == 7
        oldFolder = pwd;
        cd(runFolder);
        cleanup = onCleanup(@() cd(oldFolder));
    else
        cleanup = onCleanup(@() []);
    end
end

function out = absoluteOutputPath(out)
    out = char(out);
    [folderName, baseName, ext] = fileparts(out);
    if isempty(folderName)
        folderName = pwd;
    end
    if isempty(ext)
        ext = '.html';
    end
    if ~exist(folderName, 'dir')
        mkdir(folderName);
    end
    out = canonicalPath(fullfile(folderName, [baseName ext]));
end

function artifacts = emptyArtifacts(htmlFile)
    artifacts = struct('htmlFile', string(htmlFile), ...
        'jsonFile', "", 'functionCount', 0);
end

function root = repoRoot()
    toolFolder = fileparts(mfilename('fullpath'));
    candidate = fileparts(fileparts(toolFolder));
    if exist(fullfile(candidate, 'labkit_launcher.m'), 'file') == 2
        root = candidate;
    else
        root = pwd;
    end
end

function label = targetLabelText(target)
    if isa(target, 'function_handle')
        label = func2str(target);
    elseif ischar(target) || isstring(target)
        label = char(target);
    else
        label = class(target);
    end
end

function ext = fileExt(filePath)
    [~, ~, ext] = fileparts(filePath);
end

function tf = isOnPath(folderName)
    folderName = canonicalPath(folderName);
    pathParts = regexp(path, pathsep, 'split');
    tf = false;
    for k = 1:numel(pathParts)
        if ~isempty(pathParts{k}) && isSamePath(canonicalPath(pathParts{k}), folderName)
            tf = true;
            return;
        end
    end
end

function resolvedPath = canonicalPath(filePath)
    try
        resolvedPath = char( ...
            labkit.app.internal.filesystem.absolutePath(filePath));
    catch
        resolvedPath = char(filePath);
    end
end

function tf = isSamePath(left, right)
    if ispc
        tf = strcmpi(char(left), char(right));
    else
        tf = strcmp(char(left), char(right));
    end
end

function field = normalizeSortField(field)
    allowed = ["Index", "FunctionName", "Type", "NumCalls", ...
        "SelfTime", "TotalTime", "ExecutedLineTime"];
    field = string(field);
    if ~any(field == allowed)
        field = "SelfTime";
    end
end

function tf = isTextScalar(value)
    tf = ischar(value) || (isstring(value) && isscalar(value));
end

function tf = isLogicalScalar(value)
    tf = (islogical(value) || isnumeric(value)) && isscalar(value);
end

function tf = isPositiveScalar(value)
    tf = isnumeric(value) && isscalar(value) && isfinite(value) && value > 0;
end
