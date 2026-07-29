function file = visualEvidencePath(name, extension)
%VISUALEVIDENCEPATH Reserve a reviewable image in the current test run.
%   FILE = labkittest.visualEvidencePath(NAME, EXTENSION) returns an absolute
%   path below the current run's visual-evidence folder and creates that
%   folder when needed. NAME is converted to a portable filename. EXTENSION
%   is a scalar text value such as ".png".
%
%   The official runner publishes the folder below
%   artifacts/test-results/<profile>/visual-evidence. Direct focused use
%   outside the runner falls back to artifacts/test-results/visual-local.
%
%   Use this for deterministic rendered output that supports human or visual
%   model review. The same test must still make an automated assertion for
%   its executable contract; visual evidence is not a passing result.
arguments
    name (1, 1) string
    extension (1, 1) string
end

portableName = string(regexprep(char(name), '[^A-Za-z0-9._-]', '-'));
portableName = string(regexprep(char(portableName), '^-+|-+$', ''));
if strlength(portableName) == 0
    error("LabKit:TestArtifacts:InvalidVisualEvidenceName", ...
        "Visual evidence requires a nonempty portable name.");
end
if ~startsWith(extension, ".") || ...
        ~isempty(regexp(char(extension), '[^A-Za-z0-9.]', 'once'))
    error("LabKit:TestArtifacts:InvalidVisualEvidenceExtension", ...
        "Visual evidence extension must look like '.png'.");
end

runFolder = string(getenv("LABKIT_TEST_ARTIFACT_FOLDER"));
if strlength(runFolder) == 0
    packageFolder = fileparts(mfilename("fullpath"));
    root = fileparts(fileparts(packageFolder));
    runFolder = fullfile(root, "artifacts", "test-results", "visual-local");
end
folder = fullfile(runFolder, "visual-evidence");
if exist(folder, "dir") ~= 7
    mkdir(folder);
end
file = string(fullfile(folder, portableName + extension));
end
