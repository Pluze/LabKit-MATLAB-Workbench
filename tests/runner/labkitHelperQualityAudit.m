function audit = labkitHelperQualityAudit(root, varargin)
%LABKITHELPERQUALITYAUDIT Dry-run report for short helper classification.
% Expected caller: migration planning and project tests. Inputs are the repo
% root and optional MaxLines/Scope values. Output is a table describing short
% helper files, call/test references, package role, and a non-blocking
% recommendation. Side effects: reads tracked MATLAB source files.

    if nargin < 1 || strlength(string(root)) == 0
        root = labkitRepoRoot();
    end
    opts = parseOptions(varargin{:});
    files = gitTrackedMatlabFiles(root);
    files = files(startsWith(files, opts.scope + "/"));
    files = files(arrayfun(@(p) isCandidateHelper(root, p, opts.maxLines), files));

    allSource = readSourceCorpus(root, gitTrackedMatlabFiles(root));
    rows = cell(numel(files), 9);
    for k = 1:numel(files)
        path = files(k);
        lines = readFileLines(fullfile(root, char(path)));
        basename = helperName(path);
        rows{k, 1} = path;
        rows{k, 2} = numel(lines);
        rows{k, 3} = rolePackage(path);
        rows{k, 4} = functionCount(lines);
        rows{k, 5} = approximateCallCount(allSource, basename);
        rows{k, 6} = publicStatus(path);
        rows{k, 7} = directUnitTestReferences(allSource.unit, basename, path);
        rows{k, 8} = allowedExceptionClass(path);
        rows{k, 9} = recommendation(rows{k, 2}, rows{k, 4}, rows{k, 5}, ...
            rows{k, 7}, rows{k, 8});
    end

    audit = cell2table(rows, 'VariableNames', { ...
        'RelativePath', 'Lines', 'RolePackage', 'FunctionCount', ...
        'CallCount', 'PublicStatus', 'DirectUnitTestReferences', ...
        'AllowedException', 'Recommendation'});
    if ~isempty(audit)
        audit = sortrows(audit, {'Recommendation', 'Lines', 'RelativePath'});
    end
end

function opts = parseOptions(varargin)
    opts = struct("maxLines", 20, "scope", "apps");
    if mod(numel(varargin), 2) ~= 0
        error("LabKit:HelperAudit:InvalidOptions", ...
            "Options must be name-value pairs.");
    end
    for k = 1:2:numel(varargin)
        name = lower(string(varargin{k}));
        value = varargin{k + 1};
        switch name
            case "maxlines"
                opts.maxLines = double(value);
            case "scope"
                opts.scope = strip(string(value), "right", "/");
            otherwise
                error("LabKit:HelperAudit:InvalidOptions", ...
                    "Unsupported option %s.", name);
        end
    end
end

function tf = isCandidateHelper(root, path, maxLines)
    path = string(path);
    [~, name, ext] = fileparts(char(path));
    if string(ext) ~= ".m"
        tf = false;
        return;
    end
    if any(name == ["run", "requirements", "version"])
        tf = false;
        return;
    end
    if startsWith(name, "labkit_")
        tf = false;
        return;
    end
    if contains(path, "/+ui/buildSpec.m")
        tf = false;
        return;
    end
    tf = fileLineCount(fullfile(root, char(path))) <= maxLines;
end

function count = fileLineCount(path)
    fid = fopen(path, "r");
    if fid < 0
        count = inf;
        return;
    end
    cleaner = onCleanup(@() fclose(fid));
    count = 0;
    while ~feof(fid)
        fgetl(fid);
        count = count + 1;
    end
end

function files = gitTrackedMatlabFiles(root)
    command = "git -C " + shellQuote(root) + " ls-files '*.m'";
    [status, out] = system(command);
    if status ~= 0
        error("LabKit:HelperAudit:GitFailed", ...
            "Could not list tracked MATLAB files.");
    end
    files = splitlines(string(out));
    files = files(strlength(files) > 0);
    files = files(arrayfun(@(p) exist(fullfile(root, char(p)), "file") == 2, files));
end

function value = shellQuote(value)
    value = string(value);
    value = replace(value, "'", "'\''");
    value = "'" + value + "'";
end

function corpus = readSourceCorpus(root, files)
    corpus.all = "";
    corpus.unit = "";
    for k = 1:numel(files)
        text = string(fileread(fullfile(root, char(files(k)))));
        corpus.all = corpus.all + newline + text;
        if startsWith(files(k), "tests/cases/unit/")
            corpus.unit = corpus.unit + newline + text;
        end
    end
end

function lines = readFileLines(filepath)
    text = string(fileread(filepath));
    lines = splitlines(text);
    if ~isempty(lines) && lines(end) == ""
        lines(end) = [];
    end
end

function name = helperName(path)
    [~, name] = fileparts(char(path));
    name = string(name);
end

function role = rolePackage(path)
    parts = split(string(path), "/");
    packageParts = parts(startsWith(parts, "+"));
    packageParts = erase(packageParts, "+");
    if isempty(packageParts)
        role = "";
    else
        role = strjoin(packageParts, ".");
    end
end

function n = functionCount(lines)
    n = sum(startsWith(strtrim(lines), "function "));
end

function n = approximateCallCount(corpus, name)
    pattern = "(?<![A-Za-z0-9_])" + regexptranslate("escape", name) + "\s*\(";
    matches = regexp(corpus.all, pattern, "match");
    n = max(0, numel(matches) - 1);
end

function statusText = publicStatus(path)
    if contains(path, "/private/")
        statusText = "private";
    elseif contains(path, "/+")
        statusText = "app-owned-package";
    else
        statusText = "entry-folder";
    end
end

function n = directUnitTestReferences(unitCorpus, name, path)
    tokens = [name, rolePackage(path) + "." + name];
    n = 0;
    for k = 1:numel(tokens)
        if strlength(tokens(k)) == 0
            continue;
        end
        pattern = "(?<![A-Za-z0-9_])" + regexptranslate("escape", tokens(k));
        n = n + numel(regexp(unitCorpus, pattern, "match"));
    end
end

function className = allowedExceptionClass(path)
    path = string(path);
    [~, name] = fileparts(char(path));
    if contains(path, "/+ui/")
        className = "ui-builder-adapter";
    elseif contains(path, "/+state/") && any(startsWith(string(name), ["empty", "default"]))
        className = "state-factory";
    elseif contains(path, "/+io/") && any(contains(string(name), ["Filter", "Extensions"]))
        className = "input-policy";
    elseif contains(path, "/+export/") && startsWith(string(name), "write")
        className = "export-side-effect";
    elseif startsWith(path, "tests/shared/")
        className = "test-api";
    else
        className = "";
    end
end

function text = recommendation(lines, functionCountValue, callCount, testRefs, exceptionClass)
    if strlength(string(exceptionClass)) > 0
        text = "keep-exception";
    elseif testRefs > 0 || callCount > 1
        text = "review-contract";
    elseif lines <= 12 && functionCountValue <= 1 && callCount <= 1
        text = "inline-or-merge-candidate";
    else
        text = "review";
    end
end
