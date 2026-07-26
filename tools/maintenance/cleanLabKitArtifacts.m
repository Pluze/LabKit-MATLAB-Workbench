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
%       removedTargets contains only successfully removed generated targets.
%       errors contains removal failures; invalid roots or unsafe targets throw
%       a stable error instead of performing any deletion.
%
% Deletion range:
%   This tool removes only root/artifacts. It never removes projects, source,
%   application folders, exported laboratory data, or a target that resolves
%   outside root. The operation is idempotent when artifacts is absent.
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
    relativeTarget = "artifacts";
    target = fullfile(root, char(relativeTarget));
    removedTargets = strings(0, 1);
    errors = strings(0, 1);

    notifyProgress(progressFcn, "Checking cleanup root...", 0.05);
    notifyProgress(progressFcn, "Finding generated artifact targets...", 0.20);
    notifyProgress(progressFcn, "Checking " + relativeTarget + "...", 0.25);
    validateCleanLabKitArtifactsTarget(root, target, relativeTarget);
    if exist(target, "dir") == 7
        notifyProgress(progressFcn, "Removing " + relativeTarget + "...", 0.55);
        try
            rmdir(target, "s");
            removedTargets(end + 1, 1) = relativeTarget;
        catch cause
            errors(end + 1, 1) = string(cause.message);
        end
    elseif exist(target, "file") == 2
        notifyProgress(progressFcn, "Removing " + relativeTarget + "...", 0.55);
        try
            delete(target);
            removedTargets(end + 1, 1) = relativeTarget;
        catch cause
            errors(end + 1, 1) = string(cause.message);
        end
    else
        notifyProgress(progressFcn, relativeTarget + " is already clean.", 0.85);
    end
    notifyProgress(progressFcn, "Clean Artifacts complete.", 1.00);
    result = struct("root", string(root), "removedCount", numel(removedTargets), ...
        "removedTargets", removedTargets, "errors", errors);
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
file = java.io.File(char(filepath));
linkOptions = javaArray("java.nio.file.LinkOption", 0);
resolvedPath = char(file.toPath().toRealPath(linkOptions).toString());
end

function tf = isFilesystemRoot(filepath)
file = java.io.File(char(filepath));
parent = file.getParentFile();
tf = isempty(parent) || isSamePath(filepath, char(parent.getCanonicalPath()));
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
