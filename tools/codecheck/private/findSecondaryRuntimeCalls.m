function violations = findSecondaryRuntimeCalls(root, files)
%FINDSECONDARYRUNTIMECALLS Find direct non-MATLAB runtime entry points.
% Expected caller: runCodecheckReport. Every supplied MATLAB file is scanned.
% Test-only shell boundaries require an exact file/count allowance plus a
% nearby Secondary-runtime test boundary marker; all other categories are
% zero-tolerance across production, tools, and tests.

    rules = runtimeRules();
    allowances = shellAllowances();
    records = strings(numel(files) * numel(rules), 1);
    recordCount = 0;
    allowanceCounts = zeros(numel(allowances), 1);
    allowanceApplies = false(numel(allowances), 1);

    for file = string(files(:)).'
        source = fileread(file);
        relativeFile = repositoryRelativePath(root, file);
        allowanceApplies(string({allowances.File}) == relativeFile) = true;
        for ruleIndex = 1:numel(rules)
            [starts, matches] = regexp(source, rules(ruleIndex).Expression, ...
                "start", "match");
            for matchIndex = 1:numel(starts)
                line = 1 + count(string(source(1:starts(matchIndex) - 1)), newline);
                if isAllowedShellBoundary(relativeFile, ...
                        rules(ruleIndex).Name, source, starts(matchIndex), ...
                        allowances, allowanceCounts)
                    allowanceIndex = findAllowance(relativeFile, ...
                        rules(ruleIndex).Name, allowances);
                    allowanceCounts(allowanceIndex) = ...
                        allowanceCounts(allowanceIndex) + 1;
                    continue;
                end
                recordCount = recordCount + 1;
                records(recordCount) = compose("%s:%d [%s] %s", ...
                    relativeFile, line, rules(ruleIndex).Name, ...
                    strip(string(matches{matchIndex})));
            end
        end
    end

    for allowanceIndex = 1:numel(allowances)
        if allowanceApplies(allowanceIndex) && ...
                allowanceCounts(allowanceIndex) ~= allowances(allowanceIndex).Count
            recordCount = recordCount + 1;
            records(recordCount) = compose( ...
                "%s [allowance] expected %d marked %s call(s), found %d", ...
                allowances(allowanceIndex).File, ...
                allowances(allowanceIndex).Count, ...
                allowances(allowanceIndex).Category, ...
                allowanceCounts(allowanceIndex));
        end
    end
    violations = records(1:recordCount);
end

function rules = runtimeRules()
names = ["java" "java-api" "java-runtime" "java-import" ...
    "python" "python-runtime" "shell" "shell-escape" "native" ...
    "dotnet" "activex"];
expressions = [ ...
    "(?<!import )(?<![\w.])java\." ...
    "(?<![\w.])java(?:Method|Object|Array|classpath)\s*\(" ...
    "(?<![\w.])(?:usejava|javaaddpath|javarmpath)\s*\(" ...
    "(?<!\w)import\s+java\." ...
    "(?<![\w.])py\." ...
    "(?<![\w.])(?:pyenv|pyrun|pyrunfile|conda)\s*\(" ...
    "(?<![\w.])(?:system|unix|dos|perl)\s*\(" ...
    "(?m)^[ \t]*!" ...
    "(?<![\w.])(?:loadlibrary|calllib|mex)\s*\(" ...
    "(?<![\w.])NET\." ...
    "(?<![\w.])(?:actxcontrol|actxserver|actxGetRunningServer)\s*\(" ];
rules = struct("Name", cellstr(names), "Expression", cellstr(expressions));
end

function allowances = shellAllowances()
files = [ ...
    "tests/+labkittest/plan.m"
    "tests/specs/repository/TestArchitectureSpec.m"
    "tests/specs/tests/labkittest/TestCatalogSpec.m"
    "tests/specs/tools/maintenance/CleanLabKitArtifactsSpec.m"];
counts = [2; 1; 1; 1];
allowances = struct("File", cellstr(files), ...
    "Category", repmat({"shell"}, numel(files), 1), ...
    "Count", num2cell(counts));
end

function tf = isAllowedShellBoundary(file, category, source, startIndex, ...
        allowances, allowanceCounts)
allowanceIndex = findAllowance(file, category, allowances);
if isempty(allowanceIndex) || ...
        allowanceCounts(allowanceIndex) >= allowances(allowanceIndex).Count
    tf = false;
    return;
end
lineStart = find(source(1:startIndex - 1) == newline, 2, "last");
if numel(lineStart) < 2
    contextStart = 1;
else
    contextStart = lineStart(1) + 1;
end
context = string(source(contextStart:startIndex - 1));
tf = contains(context, "Secondary-runtime test boundary:");
end

function index = findAllowance(file, category, allowances)
index = find(string({allowances.File}) == file & ...
    string({allowances.Category}) == category, 1);
end

function relative = repositoryRelativePath(root, file)
root = string(root);
file = string(file);
prefix = root;
if ~endsWith(prefix, filesep)
    prefix = prefix + filesep;
end
if startsWith(file, prefix)
    relative = extractAfter(file, strlength(prefix));
else
    relative = file;
end
relative = replace(relative, "\", "/");
end
