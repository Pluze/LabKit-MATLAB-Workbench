function output = runLabKitTestTarget(action, options)
%RUNLABKITTESTTARGET Run one focused LabKit test target consistently.
% Expected caller: Codex agents using the labkit-test-planner skill.
% Inputs:
%   action        "list-file", "run-file", "run-test", or "run-suite"
%   options.File  test file beneath tests/cases; optional for run-test when
%                 the canonical class name has one unique owning file
%   options.Test  canonical ClassName or ClassName/methodName selector
%   options.Suite suite folder relative to tests/cases
%   options.Gui    include hidden GUI tests for a suite; file actions infer it
% Output:
%   output        runLabKitTests result or list-only result
% Side effects: runs MATLAB tests and writes normal ignored test artifacts.

    arguments
        action (1, 1) string {mustBeMember(action, ...
            ["list-file", "run-file", "run-test", "run-suite"])}
        options.File (1, 1) string = ""
        options.Test (1, 1) string = ""
        options.Suite (1, 1) string = ""
        options.Gui (1, 1) logical = false
    end

    skillRoot = fileparts(fileparts(mfilename("fullpath")));
    repoRoot = fileparts(fileparts(fileparts(skillRoot)));
    addpath(fullfile(repoRoot, "tests"));

    commonArgs = { ...
        "GuiMode", "hidden", ...
        "HtmlReport", false, ...
        "RunName", "focused"};

    switch action
        case "list-file"
            requireValue(options.File, "File", action);
            rejectValue(options.Test, "Test", action);
            rejectValue(options.Suite, "Suite", action);
            output = runLabKitTests( ...
                "Files", options.File, ...
                "IncludeGui", isGuiTestFile(repoRoot, options.File), ...
                "ListOnly", true, ...
                commonArgs{:});
        case "run-file"
            requireValue(options.File, "File", action);
            rejectValue(options.Test, "Test", action);
            rejectValue(options.Suite, "Suite", action);
            output = runLabKitTests( ...
                "Files", options.File, ...
                "IncludeGui", isGuiTestFile(repoRoot, options.File), ...
                commonArgs{:});
        case "run-test"
            requireValue(options.Test, "Test", action);
            rejectValue(options.Suite, "Suite", action);
            testFile = options.File;
            if strlength(testFile) == 0
                testFile = resolveOwningTestFile(repoRoot, options.Test);
            end
            output = runLabKitTests( ...
                "Files", testFile, ...
                "Tests", options.Test, ...
                "IncludeGui", isGuiTestFile(repoRoot, testFile), ...
                commonArgs{:});
        case "run-suite"
            requireValue(options.Suite, "Suite", action);
            rejectValue(options.File, "File", action);
            rejectValue(options.Test, "Test", action);
            output = runLabKitTests( ...
                "Suites", options.Suite, ...
                "IncludeGui", options.Gui || isGuiSuite(options.Suite), ...
                commonArgs{:});
    end
end

function file = resolveOwningTestFile(repoRoot, selector)
    parts = split(selector, "/");
    className = parts(1);
    if strlength(className) == 0 || ~isvarname(className)
        error("LabKit:AgentTestTarget:InvalidSelector", ...
            "run-test Test must begin with a canonical MATLAB test class name.");
    end
    matches = dir(fullfile( ...
        repoRoot, "tests", "cases", "**", className + ".m"));
    matches = matches(~[matches.isdir]);
    if isempty(matches)
        error("LabKit:AgentTestTarget:OwnerNotFound", ...
            "No test file owns canonical class %s.", className);
    end
    if numel(matches) > 1
        candidates = string(fullfile( ...
            {matches.folder}, {matches.name}));
        error("LabKit:AgentTestTarget:AmbiguousOwner", ...
            "Canonical class %s has multiple owning files; supply File:%s%s", ...
            className, newline, strjoin(candidates, newline));
    end
    file = string(fullfile(matches(1).folder, matches(1).name));
end

function tf = isGuiTestFile(repoRoot, file)
    file = normalizePath(file);
    guiRoot = lower(normalizePath( ...
        fullfile(repoRoot, "tests", "cases", "gui"))) + "/";
    isAbsolute = startsWith(file, "/") || startsWith(file, "//") || ...
        ~isempty(regexp(file, "^[A-Za-z]:/", "once"));
    if isAbsolute
        fullFile = lower(file);
    else
        fullFile = lower(normalizePath(fullfile(repoRoot, file)));
    end
    tf = startsWith(fullFile, guiRoot) || ...
        startsWith(lower(file), "gui/");
end

function tf = isGuiSuite(suite)
    suite = strip(normalizePath(suite), "both", "/");
    tf = startsWith(suite, "gui/");
end

function path = normalizePath(path)
    path = replace(string(path), "\", "/");
end

function requireValue(value, name, action)
    if strlength(value) == 0
        error("LabKit:AgentTestTarget:MissingOption", ...
            "%s requires the %s option.", action, name);
    end
end

function rejectValue(value, name, action)
    if strlength(value) > 0
        error("LabKit:AgentTestTarget:UnexpectedOption", ...
            "%s does not accept the %s option.", action, name);
    end
end
