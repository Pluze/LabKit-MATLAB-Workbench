function result = cleanLabKitArtifacts(root, varargin)
%CLEANLABKITARTIFACTS Remove only generated LabKit artifact folders.
%
% Syntax:
%   result = cleanLabKitArtifacts
%   result = cleanLabKitArtifacts(root)
%   result = cleanLabKitArtifacts(root, ProgressFcn=fcn)
%
% Inputs:
%   root - LabKit installation folder. When omitted, uses the repository root
%       containing this tool. The folder must contain labkit_launcher.m and may
%       not be a filesystem root.
%
% Name-Value Arguments:
%   ProgressFcn - Function handle called as ProgressFcn(message, value), where
%       value is a finite fraction from 0 through 1. The callback is optional.
%
% Outputs:
%   result - Scalar struct with root, removedCount, removedTargets, and errors.
%       removedTargets contains root-relative successfully removed targets.
%       errors contains removal failures; invalid roots or unsafe targets throw
%       a stable error instead of performing any deletion.
%
% Deletion range:
%   This tool removes generated content under root/artifacts. It preserves
%   artifacts/worktrees and its contents, including unfinished task code.
%   When worktrees is present, only its siblings are removed and artifacts
%   itself remains. Otherwise the entire artifacts target is removed.
%   It never removes application folders or a target that resolves outside
%   root. The operation is idempotent when no generated targets remain.
%
% Errors:
%   cleanLabKitArtifacts:InvalidRoot rejects non-scalar, empty, filesystem-root,
%   and non-LabKit roots. cleanLabKitArtifacts:UnsafeTarget rejects a generated
%   target that resolves outside the validated root.
%   cleanLabKitArtifacts:InvalidOption rejects unsupported name-value syntax.
%   cleanLabKitArtifacts:InvalidProgressFcn rejects a non-function-handle
%   ProgressFcn. Deletion failures are collected in result.errors; exceptions
%   thrown by ProgressFcn propagate to the caller.
%
% See also rmdir, delete

    if nargin < 1 || isempty(root)
        root = defaultRoot();
    end
    progressFcn = parseOptions(varargin{:});
    root = validateRoot(root);
    notifyProgress(progressFcn, "Checking cleanup root...", 0.05);
    notifyProgress(progressFcn, "Finding generated artifact targets...", 0.20);
    relativeTargets = generatedTargets(root);
    removed = false(numel(relativeTargets), 1);
    errors = strings(numel(relativeTargets), 1);
    errorCount = 0;
    % Validate the complete removal set before deleting any generated content.
    for k = 1:numel(relativeTargets)
        relativeTarget = relativeTargets(k);
        validateCleanLabKitArtifactsTarget(root, ...
            fullfile(root, relativeTarget), relativeTarget);
    end
    notifyProgress(progressFcn, "Generated artifact targets checked.", 0.25);
    for k = 1:numel(relativeTargets)
        relativeTarget = relativeTargets(k);
        target = fullfile(root, char(relativeTarget));
        notifyProgress(progressFcn, "Removing " + relativeTarget + "...", ...
            0.25 + 0.60 * k / numel(relativeTargets));
        if exist(target, "dir") == 7
            try
                rmdir(target, "s");
                removed(k) = true;
            catch cause
                if string(cause.identifier) == "MATLAB:RMDIR:NotADirectory"
                    error("cleanLabKitArtifacts:UnsafeTarget", ...
                        "Clean Artifacts refused a linked generated target: %s", ...
                        target);
                end
                errorCount = errorCount + 1;
                errors(errorCount) = string(cause.message);
            end
        elseif exist(target, "file") == 2
            try
                delete(target);
                removed(k) = true;
            catch cause
                errorCount = errorCount + 1;
                errors(errorCount) = string(cause.message);
            end
        end
    end
    notifyProgress(progressFcn, "Clean Artifacts complete.", 1.00);
    removedTargets = relativeTargets(removed);
    result = struct("root", string(root), "removedCount", numel(removedTargets), ...
        "removedTargets", removedTargets, "errors", errors(1:errorCount));
end

function targets = generatedTargets(root)
% The cleanup owner reserves worktrees without inspecting task or Git state.
artifactRoot = fullfile(root, "artifacts");
validateCleanLabKitArtifactsTarget(root, artifactRoot, "artifacts");
targets = "artifacts";
if ~isfolder(artifactRoot)
    return;
end
entries = dir(artifactRoot);
names = string({entries.name}).';
if ~any(strcmpi(names, "worktrees"))
    return;
end
names = names(~ismember(names, ["."; ".."]) & ~strcmpi(names, "worktrees"));
targets = fullfile("artifacts", names);
end

function root = defaultRoot()
root = fileparts(fileparts(fileparts(mfilename("fullpath"))));
end

function progressFcn = parseOptions(varargin)
progressFcn = [];
if isempty(varargin)
    return;
end
if numel(varargin) ~= 2 || ~(ischar(varargin{1}) || ...
        (isstring(varargin{1}) && isscalar(varargin{1}))) || ...
        ~strcmpi(string(varargin{1}), "ProgressFcn")
    error("cleanLabKitArtifacts:InvalidOption", ...
        "Use the ProgressFcn name-value argument.");
end
progressFcn = varargin{2};
if ~isa(progressFcn, "function_handle")
    error("cleanLabKitArtifacts:InvalidProgressFcn", ...
        "ProgressFcn must be a function handle.");
end
end

function root = validateRoot(root)
if ~(ischar(root) || (isstring(root) && isscalar(root))) || ...
        ismissing(string(root)) || strlength(strip(string(root))) == 0
    error("cleanLabKitArtifacts:InvalidRoot", ...
        "Root must be nonempty scalar text naming a LabKit installation.");
end
if exist(char(root), "dir") ~= 7
    error("cleanLabKitArtifacts:InvalidRoot", ...
        "Root must name an existing LabKit installation folder.");
end
try
    root = realExistingPath(root);
catch
    error("cleanLabKitArtifacts:InvalidRoot", ...
        "Root must resolve to an accessible LabKit installation folder.");
end
if isFilesystemRoot(root) || exist(fullfile(root, "labkit_launcher.m"), "file") ~= 2
    error("cleanLabKitArtifacts:InvalidRoot", ...
        "Clean Artifacts refused unsafe or non-LabKit root: %s", root);
end
end

function resolvedPath = realExistingPath(filepath)
resolvedPath = char(labkit.app.internal.filesystem.absolutePath(filepath));
end

function tf = isFilesystemRoot(filepath)
parent = fileparts(filepath);
tf = strlength(string(parent)) == 0 || isSamePath(filepath, parent);
end

function tf = isSamePath(left, right)
if ispc
    tf = strcmpi(char(left), char(right));
else
    tf = strcmp(char(left), char(right));
end
end

function notifyProgress(progressFcn, message, value)
if ~isempty(progressFcn)
    progressFcn(char(message), value);
end
end
