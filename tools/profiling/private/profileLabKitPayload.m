function payload = profileLabKitPayload(profInfo, targetLabel, runError, wrapperPath, tagContext)
%PROFILELABKITPAYLOAD Convert MATLAB profile info to a report payload.
%
% Expected caller: tools/profiling/profileLabKitTarget.m. Inputs are a profile('info')
% struct, a display target label, an optional MException, the profiler wrapper
% path used to tag profiler-tool rows, and a project tagging context. Output is
% a JSON-serializable struct
% used by both human HTML and agent summary artifacts.

    if nargin < 5 || isempty(tagContext)
        tagContext = struct("TargetFile", "", "RepoRoot", "");
    end

    validateattributes(profInfo, {'struct'}, {'nonempty'});
    if ~isfield(profInfo, 'FunctionTable')
        error('profileLabKitPayload:InvalidProfileInfo', ...
            'Invalid profiler info: missing FunctionTable.');
    end

    ft = profInfo.FunctionTable;
    n = numel(ft);
    matlabRootValue = matlabroot;
    functions = repmat(emptyFunction(), 1, n);
    allTotal = zeros(1, n);
    allSelf = zeros(1, n);
    allCalls = zeros(1, n);

    for k = 1:n
        allTotal(k) = numScalar(ft(k), 'TotalTime', 0);
        allSelf(k) = selfTime(ft(k));
        allCalls(k) = numScalar(ft(k), 'NumCalls', 0);
    end
    maxTotal = max([allTotal(:); eps]);
    maxSelf = max([allSelf(:); eps]);

    for k = 1:n
        fileName = strField(ft(k), 'FileName');
        functions(k).Index = k;
        functions(k).FunctionName = strField(ft(k), 'FunctionName');
        functions(k).CompleteName = strField(ft(k), 'CompleteName');
        functions(k).Type = strField(ft(k), 'Type');
        functions(k).FileName = fileName;
        functions(k).ShortFileName = shortPath(fileName);
        functions(k).IsMatlabInternal = isMatlabInternal(fileName, matlabRootValue);
        functions(k).IsRepoFile = false;
        functions(k).IsProfilerTool = false;
        functions(k).SourceTag = sourceTag(false, false, functions(k).IsMatlabInternal, fileName);
        functions(k).Tags = functions(k).SourceTag;
        functions(k).NumCalls = allCalls(k);
        functions(k).TotalTime = allTotal(k);
        functions(k).SelfTime = allSelf(k);
        functions(k).ExecutedLineTime = executedLineTime(ft(k));
        functions(k).TotalTimePctOfMax = 100 * allTotal(k) / maxTotal;
        functions(k).SelfTimePctOfMax = 100 * allSelf(k) / maxSelf;
        functions(k).Extra = extraFields(ft(k));
        if isfield(ft(k), 'Parents')
            functions(k).Parents = edgesToStructArray(ft(k).Parents, ft);
        end
        if isfield(ft(k), 'Children')
            functions(k).Children = edgesToStructArray(ft(k).Children, ft);
        end
        if isfield(ft(k), 'ExecutedLines')
            functions(k).ExecutedLines = executedLinesToStructArray(ft(k).ExecutedLines);
            functions(k).ExecutedLineCount = numel(functions(k).ExecutedLines);
        end
    end

    functions = annotateSourceTags(functions, wrapperPath, tagContext);
    if isempty(functions)
        allTotal = 0;
        allSelf = 0;
        allCalls = 0;
    else
        allTotal = [functions.TotalTime];
        allSelf = [functions.SelfTime];
        allCalls = [functions.NumCalls];
    end

    runErrorText = "";
    if ~isempty(runError)
        runErrorText = string(getReport(runError, 'extended', 'hyperlinks', 'off'));
    end

    metadata = struct();
    metadata.Target = char(string(targetLabel));
    metadata.GeneratedAt = char(datetime( ...
        "now", "Format", "yyyy-MM-dd HH:mm:ss"));
    metadata.MatlabVersion = version;
    metadata.MatlabRoot = matlabRootValue;
    metadata.NumFunctions = numel(functions);
    metadata.TotalCalls = sum(allCalls);
    metadata.MaxTotalTime = max([allTotal(:); eps]);
    metadata.MaxSelfTime = max([allSelf(:); eps]);
    metadata.SumSelfTime = sum(allSelf);
    metadata.SumTotalTime = sum(allTotal);
    metadata.RunError = char(runErrorText);
    metadata.TargetFile = char(contextField(tagContext, "TargetFile"));
    metadata.RepoRoot = char(contextField(tagContext, "RepoRoot"));
    metadata.ProjectFunctions = sum([functions.IsRepoFile]);
    metadata.ProfilerToolFunctions = sum([functions.IsProfilerTool]);
    metadata.MatlabInternalFunctions = sum([functions.IsMatlabInternal]);

    payload = struct();
    payload.metadata = metadata;
    payload.profilerInfo = profilerInfo(profInfo);
    payload.functions = functions;
end

function functions = annotateSourceTags(functions, wrapperPath, tagContext)
    if isempty(functions)
        return;
    end
    repoRootValue = char(contextField(tagContext, "RepoRoot"));
    for k = 1:numel(functions)
        fileName = char(string(functions(k).FileName));
        functions(k).IsRepoFile = strlength(string(repoRootValue)) > 0 && ...
            isUnderRoot(fileName, repoRootValue);
        functions(k).IsProfilerTool = isProfilerToolFunction(functions(k), wrapperPath);
        functions(k).SourceTag = sourceTag(functions(k).IsRepoFile, ...
            functions(k).IsProfilerTool, functions(k).IsMatlabInternal, fileName);
        functions(k).Tags = functionTags(functions(k));
    end
end

function f = emptyFunction()
    f = struct( ...
        'Index', 0, 'FunctionName', '', 'CompleteName', '', 'Type', '', ...
        'FileName', '', 'ShortFileName', '', 'IsMatlabInternal', false, ...
        'IsRepoFile', false, 'IsProfilerTool', false, ...
        'SourceTag', 'unknown', 'Tags', 'unknown', ...
        'NumCalls', 0, 'TotalTime', 0, 'SelfTime', 0, ...
        'ExecutedLineCount', 0, 'ExecutedLineTime', 0, ...
        'TotalTimePctOfMax', 0, 'SelfTimePctOfMax', 0, ...
        'Parents', struct([]), 'Children', struct([]), ...
        'ExecutedLines', struct([]), 'Extra', struct());
end

function tf = isProfilerToolFunction(f, wrapperPath)
    selfFile = canonicalPath([wrapperPath '.m']);
    fn = lower(char(string(f.FunctionName)));
    fileName = char(string(f.FileName));
    [~, fileBase] = fileparts(fileName);
    isSelfFile = ~isempty(fileName) && isSamePath(canonicalPath(fileName), selfFile);
    tf = isSelfFile || startsWith(lower(fileBase), 'profilegui') || ...
        strcmpi(fileBase, 'profileLabKitTarget') || ...
        startsWith(fn, 'profilelabkit') || startsWith(fn, 'profilegui') || ...
        startsWith(fn, 'profilesave');
end

function tag = sourceTag(isRepoFile, isProfilerTool, isMatlabInternal, fileName)
    if isProfilerTool
        tag = 'profiler_tool';
    elseif isRepoFile
        tag = 'project';
    elseif isMatlabInternal
        tag = 'matlab_internal';
    elseif strlength(string(fileName)) == 0
        tag = 'unknown';
    else
        tag = 'external';
    end
end

function tags = functionTags(f)
    values = string(f.SourceTag);
    if f.IsRepoFile
        values(end + 1) = "repo";
    end
    if f.IsMatlabInternal
        values(end + 1) = "matlab_internal";
    end
    if f.IsProfilerTool
        values(end + 1) = "profiler_tool";
    end
    tags = char(strjoin(unique(values, 'stable'), ','));
end

function edges = edgesToStructArray(rawEdges, ft)
    emptyEdge = struct('Index', 0, 'FunctionName', '', 'CompleteName', '', ...
        'NumCalls', 0, 'TotalTime', 0);
    if isempty(rawEdges)
        edges = repmat(emptyEdge, 1, 0);
        return;
    end
    edges = repmat(emptyEdge, 1, numel(rawEdges));
    for k = 1:numel(rawEdges)
        idx = edgeIndex(rawEdges(k));
        edges(k).Index = idx;
        edges(k).NumCalls = numScalar(rawEdges(k), 'NumCalls', 0);
        edges(k).TotalTime = numScalar(rawEdges(k), 'TotalTime', 0);
        if idx >= 1 && idx <= numel(ft)
            edges(k).FunctionName = strField(ft(idx), 'FunctionName');
            edges(k).CompleteName = strField(ft(idx), 'CompleteName');
        end
    end
end

function idx = edgeIndex(edge)
    idx = numScalar(edge, 'Index', NaN);
    if ~isfinite(idx)
        idx = numScalar(edge, 'FunctionIndex', NaN);
    end
    if ~isfinite(idx)
        idx = 0;
    end
    idx = round(idx);
end

function lines = executedLinesToStructArray(raw)
    emptyLine = struct('Line', 0, 'Calls', 0, 'Time', 0, 'TimePerCall', 0);
    if isempty(raw)
        lines = repmat(emptyLine, 1, 0);
        return;
    end
    if isnumeric(raw)
        lines = repmat(emptyLine, 1, size(raw, 1));
        for k = 1:size(raw, 1)
            lines(k).Line = matrixValue(raw, k, 1);
            lines(k).Calls = matrixValue(raw, k, 2);
            lines(k).Time = matrixValue(raw, k, 3);
            if lines(k).Calls > 0
                lines(k).TimePerCall = lines(k).Time / lines(k).Calls;
            end
        end
        return;
    end
    if isstruct(raw)
        lines = repmat(emptyLine, 1, numel(raw));
        for k = 1:numel(raw)
            lines(k).Line = numScalar(raw(k), 'Line', numScalar(raw(k), 'LineNumber', 0));
            lines(k).Calls = numScalar(raw(k), 'Calls', numScalar(raw(k), 'NumCalls', 0));
            lines(k).Time = numScalar(raw(k), 'Time', numScalar(raw(k), 'TotalTime', 0));
            if lines(k).Calls > 0
                lines(k).TimePerCall = lines(k).Time / lines(k).Calls;
            end
        end
    end
end

function value = matrixValue(raw, row, col)
    value = 0;
    if size(raw, 2) >= col
        value = raw(row, col);
    end
end

function total = executedLineTime(f)
    total = 0;
    if ~isfield(f, 'ExecutedLines') || isempty(f.ExecutedLines)
        return;
    end
    raw = f.ExecutedLines;
    if isnumeric(raw) && size(raw, 2) >= 3
        total = sum(raw(:, 3));
    elseif isstruct(raw)
        for k = 1:numel(raw)
            total = total + numScalar(raw(k), 'Time', numScalar(raw(k), 'TotalTime', 0));
        end
    end
end

function value = selfTime(f)
    value = numScalar(f, 'SelfTime', NaN);
    if isfinite(value)
        return;
    end
    childTime = 0;
    if isfield(f, 'Children')
        for k = 1:numel(f.Children)
            childTime = childTime + numScalar(f.Children(k), 'TotalTime', 0);
        end
    end
    value = max(numScalar(f, 'TotalTime', 0) - childTime, 0);
end

function extra = extraFields(f)
    skip = {'FunctionName', 'CompleteName', 'Type', 'FileName', 'NumCalls', ...
        'TotalTime', 'SelfTime', 'Parents', 'Children', 'ExecutedLines'};
    extra = struct();
    names = fieldnames(f);
    for k = 1:numel(names)
        name = names{k};
        if any(strcmp(name, skip))
            continue;
        end
        value = f.(name);
        if ischar(value) || (isstring(value) && isscalar(value))
            extra.(name) = char(value);
        elseif isnumeric(value) || islogical(value)
            if numel(value) <= 200
                extra.(name) = value;
            else
                extra.(name) = ['array size ' mat2str(size(value))];
            end
        end
    end
end

function info = profilerInfo(profInfo)
    info = struct();
    names = fieldnames(profInfo);
    for k = 1:numel(names)
        name = names{k};
        if strcmp(name, 'FunctionTable')
            continue;
        end
        value = profInfo.(name);
        if ischar(value) || isstring(value) || isnumeric(value) || islogical(value)
            info.(name) = value;
        end
    end
end

function x = numScalar(s, fieldName, defaultValue)
    x = defaultValue;
    if isstruct(s) && isfield(s, fieldName)
        value = s.(fieldName);
        if (isnumeric(value) || islogical(value)) && isscalar(value) && isfinite(double(value))
            x = double(value);
        end
    end
end

function s = strField(x, fieldName)
    s = '';
    if isstruct(x) && isfield(x, fieldName) && ~isempty(x.(fieldName))
        s = char(string(x.(fieldName)));
    end
end

function pathText = shortPath(filePath)
    pathText = char(string(filePath));
    if isempty(pathText)
        return;
    end
    parts = regexp(strrep(pathText, filesep, '/'), '/', 'split');
    if numel(parts) > 3
        pathText = ['.../' strjoin(parts(end-2:end), '/')];
    end
end

function tf = isMatlabInternal(fileName, matlabRootValue)
    if strlength(string(fileName)) == 0
        tf = false;
    elseif ispc
        tf = startsWith(string(fileName), string(matlabRootValue), 'IgnoreCase', true);
    else
        tf = startsWith(string(fileName), string(matlabRootValue));
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

function tf = isUnderRoot(filePath, rootPath)
    if strlength(string(filePath)) == 0 || strlength(string(rootPath)) == 0
        tf = false;
        return;
    end
    filePath = canonicalPath(filePath);
    rootPath = canonicalPath(rootPath);
    if isSamePath(filePath, rootPath)
        tf = true;
        return;
    end
    prefix = [char(rootPath) filesep];
    if ispc
        tf = startsWith(string(filePath), string(prefix), 'IgnoreCase', true);
    else
        tf = startsWith(string(filePath), string(prefix));
    end
end

function value = contextField(tagContext, fieldName)
    value = "";
    if isstruct(tagContext) && isfield(tagContext, fieldName)
        value = string(tagContext.(fieldName));
    end
end
