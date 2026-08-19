function results = runFocusedSpecs(specFiles)
%RUNFOCUSEDSPECS Run explicitly selected LabKit specification files.
% This agent-only helper owns repository path setup for narrow iteration. It
% accepts only existing MATLAB specifications beneath tests/specs and fails
% the MATLAB process when any selected identity fails or is incomplete.

    if ischar(specFiles)
        specFiles = string(specFiles);
    elseif iscell(specFiles)
        specFiles = string(specFiles);
    end
    if ~(isstring(specFiles) && ~isempty(specFiles) && ...
            all(~ismissing(specFiles)) && ...
            all(strlength(strip(specFiles)) > 0))
        error("labkit:test:InvalidFocusedSpecs", ...
            "Focused specification files must be nonempty text.");
    end
    specFiles = specFiles(:);
    repoRoot = repositoryRoot();
    specsRoot = string(fullfile(repoRoot, "tests", "specs"));
    addpath(char(repoRoot), "-begin");
    addpath(char(fullfile(repoRoot, "tests")), "-begin");

    selected = cell(numel(specFiles), 1);
    selectedPaths = strings(numel(specFiles), 1);
    for index = 1:numel(specFiles)
        filepath = validatedSpecPath( ...
            repoRoot, specsRoot, specFiles(index));
        selectedPaths(index) = filepath;
        selected{index} = ...
            matlab.unittest.TestSuite.fromFile(char(filepath));
    end
    suite = [selected{:}];
    cleanups = [ ...
        configureSourcePaths(repoRoot, specsRoot, selectedPaths), ...
        configureEnvironment(selectedPaths)];
    fprintf("LabKit focused specifications: %d identities from %d file(s).\n", ...
        numel(suite), numel(specFiles));
    results = run(suite);
    disp(table(results));
    assertSuccess(results);
    delete(cleanups);
end

function cleanup = configureSourcePaths(repoRoot, specsRoot, paths)
% App specifications need their independently launchable App roots on path.
% Add every represented App rather than assuming all selected specs share the
% first App owner.
appSpecsRoot = string(fullfile(specsRoot, "apps")) + filesep;
sourceRoots = strings(numel(paths), 1);
sourceRootCount = 0;
for filepath = paths.'
    if ~startsWith(filepath, appSpecsRoot)
        continue;
    end
    relative = extractAfter(filepath, strlength(appSpecsRoot));
    parts = split(relative, filesep);
    if numel(parts) < 3 || parts(1) == "conformance"
        continue;
    end
    sourceRoot = string(fullfile(repoRoot, "apps", parts(1), parts(2)));
    if isfolder(sourceRoot)
        sourceRootCount = sourceRootCount + 1;
        sourceRoots(sourceRootCount) = sourceRoot;
    end
end
sourceRoots = sourceRoots(1:sourceRootCount);
sourceRoots = unique(sourceRoots, "stable");
sourceRoots = sourceRoots(:);
existing = string(strsplit(path, pathsep));
added = strings(numel(sourceRoots), 1);
addedCount = 0;
for sourceRootIndex = 1:numel(sourceRoots)
    sourceRoot = sourceRoots(sourceRootIndex);
    if ~any(existing == sourceRoot)
        addpath(char(sourceRoot), "-begin");
        addedCount = addedCount + 1;
        added(addedCount) = sourceRoot;
    end
end
added = added(1:addedCount);
cleanup = onCleanup(@() removeSourcePaths(added));
end

function removeSourcePaths(paths)
paths = string(paths(:));
for sourceRootIndex = 1:numel(paths)
    sourceRoot = paths(sourceRootIndex);
    if any(string(strsplit(path, pathsep)) == sourceRoot)
        rmpath(char(sourceRoot));
    end
end
end

function cleanup = configureEnvironment(paths)
hasHiddenGui = false;
for path = paths.'
    source = string(fileread(path));
    if contains(source, "Env:path-isolated")
        error("labkit:test:InvalidFocusedSpecs", ...
            "Path-isolated specifications must run through labkittest.run.");
    end
    hasHiddenGui = hasHiddenGui || contains(source, "Env:hidden-gui");
end
previous = getenv("LABKIT_GUI_TEST_MODE");
cleanup = onCleanup(@() setenv("LABKIT_GUI_TEST_MODE", previous));
if hasHiddenGui
    setenv("LABKIT_GUI_TEST_MODE", "hidden");
end
end

function root = repositoryRoot()
root = string(fileparts(mfilename("fullpath")));
for index = 1:4
    root = string(fileparts(root));
end
end

function filepath = validatedSpecPath(repoRoot, specsRoot, value)
value = strip(string(value));
if contains(replace(value, "\\", "/"), "../") || ...
        endsWith(replace(value, "\\", "/"), "/..")
    error("labkit:test:InvalidFocusedSpecs", ...
        "Focused specification paths cannot traverse parent folders.");
end
if isAbsolutePath(value)
    filepath = value;
else
    filepath = fullfile(repoRoot, value);
end
filepath = string(filepath);
prefix = specsRoot + filesep;
if ~(startsWith(filepath, prefix) && endsWith(filepath, ".m") && ...
        isfile(filepath))
    error("labkit:test:InvalidFocusedSpecs", ...
        "Focused specification must be an existing .m file under tests/specs.");
end
end

function tf = isAbsolutePath(value)
tf = startsWith(value, filesep) || ...
    ~isempty(regexp(char(value), '^[A-Za-z]:[\\/]', 'once'));
end
