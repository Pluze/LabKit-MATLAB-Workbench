function paths = labkitArtifactPaths(varargin)
%LABKITARTIFACTPATHS Return standard LabKit test artifact paths.
%
% Expected caller: runners, tests, and GUI artifact helpers. Options:
%   Root   artifact root directory, default <repo>/artifacts
%   RunName optional run name used to namespace official build artifacts
%   Create logical flag that creates directories when true
%
% Output fields include JUnit XML, HTML test results, coverage, MATLAB log,
% GUI trace, and GUI snapshot locations.

    p = inputParser;
    p.addParameter("Root", defaultArtifactRoot(), @(v) ischar(v) || isstring(v));
    p.addParameter("RunName", getenv("LABKIT_RUN_NAME"), @isTextScalar);
    p.addParameter("Create", false, @(v) islogical(v) || isnumeric(v));
    p.parse(varargin{:});

    artifactRoot = char(p.Results.Root);
    runName = sanitizeRunName(p.Results.RunName);
    createDirs = logical(p.Results.Create);

    paths = struct();
    paths.root = artifactRoot;
    paths.runName = runName;
    paths.testResults = artifactPath(artifactRoot, "test-results", runName);
    paths.junitXml = fullfile(paths.testResults, "junit.xml");
    paths.testHtml = fullfile(paths.testResults, "html");
    paths.coverage = artifactPath(artifactRoot, "coverage", runName);
    paths.coberturaXml = fullfile(paths.coverage, "cobertura.xml");
    paths.coverageHtml = fullfile(paths.coverage, "html");
    paths.logs = artifactPath(artifactRoot, "logs", runName);
    paths.matlabLog = fullfile(paths.logs, "matlab.log");
    paths.gui = artifactPath(artifactRoot, "gui", runName);
    paths.guiTrace = fullfile(paths.gui, "trace");
    paths.guiSnapshots = fullfile(paths.gui, "snapshots");

    if createDirs
        ensureDirectory(paths.root);
        ensureDirectory(paths.testResults);
        ensureDirectory(paths.testHtml);
        ensureDirectory(paths.coverage);
        ensureDirectory(paths.coverageHtml);
        ensureDirectory(paths.logs);
        ensureDirectory(paths.guiTrace);
        ensureDirectory(paths.guiSnapshots);
    end
end

function path = artifactPath(root, category, runName)
    if strlength(runName) > 0
        path = fullfile(root, category, char(runName));
    else
        path = fullfile(root, category);
    end
end

function runName = sanitizeRunName(value)
    runName = string(value);
    if strlength(runName) == 0
        return;
    end
    runName = regexprep(runName, "[^A-Za-z0-9_.-]+", "_");
    runName = regexprep(runName, "^_+|_+$", "");
    if strlength(runName) == 0
        runName = "run";
    end
end

function root = defaultArtifactRoot()
    envRoot = getenv("LABKIT_ARTIFACTS");
    if strlength(string(envRoot)) > 0
        root = char(envRoot);
    else
        root = fullfile(labkitRepoRoot(), "artifacts");
    end
end

function ensureDirectory(folder)
    if exist(folder, "dir") ~= 7
        mkdir(folder);
    end
end

function tf = isTextScalar(value)
    tf = ischar(value) || (isstring(value) && isscalar(value));
end
