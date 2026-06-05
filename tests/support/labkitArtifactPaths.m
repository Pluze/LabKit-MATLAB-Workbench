function paths = labkitArtifactPaths(varargin)
%LABKITARTIFACTPATHS Return standard LabKit test artifact paths.
%
% Expected caller: runners, tests, and GUI artifact helpers. Options:
%   Root   artifact root directory, default <repo>/artifacts
%   Create logical flag that creates directories when true
%
% Output fields include JUnit XML, HTML test results, coverage, MATLAB log,
% GUI trace, and GUI snapshot locations.

    p = inputParser;
    p.addParameter("Root", defaultArtifactRoot(), @(v) ischar(v) || isstring(v));
    p.addParameter("Create", false, @(v) islogical(v) || isnumeric(v));
    p.parse(varargin{:});

    artifactRoot = char(p.Results.Root);
    createDirs = logical(p.Results.Create);

    paths = struct();
    paths.root = artifactRoot;
    paths.testResults = fullfile(artifactRoot, "test-results");
    paths.junitXml = fullfile(paths.testResults, "junit.xml");
    paths.testHtml = fullfile(paths.testResults, "html");
    paths.coverage = fullfile(artifactRoot, "coverage");
    paths.coberturaXml = fullfile(paths.coverage, "cobertura.xml");
    paths.coverageHtml = fullfile(paths.coverage, "html");
    paths.logs = fullfile(artifactRoot, "logs");
    paths.matlabLog = fullfile(paths.logs, "matlab.log");
    paths.gui = fullfile(artifactRoot, "gui");
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
