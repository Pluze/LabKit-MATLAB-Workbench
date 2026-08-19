function validateCleanLabKitArtifactsTarget(root, target, relativeTarget)
%VALIDATECLEANLABKITARTIFACTSTARGET Reject a cleanup target outside its root.
% Expected caller: cleanLabKitArtifacts. Inputs are one validated root, the
% concrete generated target, and its fixed relative name. No deletion occurs.

    if exist(target, "dir") ~= 7 && exist(target, "file") ~= 2
        return;
    end
    try
        canonicalRoot = realExistingPath(root);
        canonicalTarget = realExistingPath(target);
    catch
        error("cleanLabKitArtifacts:UnsafeTarget", ...
            "Clean Artifacts refused a generated target that cannot be resolved safely.");
    end
    expectedTarget = lexicalPath(fullfile(canonicalRoot, char(relativeTarget)));
    if ~isSamePath(canonicalTarget, expectedTarget) || ...
            isSamePath(canonicalTarget, canonicalRoot) || ...
            ~isDescendant(canonicalTarget, canonicalRoot)
        error("cleanLabKitArtifacts:UnsafeTarget", ...
            "Clean Artifacts refused generated target outside root: %s", target);
    end
end

function resolvedPath = realExistingPath(filepath)
filepath = char(filepath);
if exist(filepath, "dir") == 7
    originalFolder = pwd;
    cleanup = onCleanup(@() cd(originalFolder));
    cd(filepath);
    resolvedPath = pwd;
    clear cleanup
    return;
end
[folder, name, extension] = fileparts(filepath);
if strlength(string(folder)) == 0
    folder = ".";
end
originalFolder = pwd;
cleanup = onCleanup(@() cd(originalFolder));
cd(folder);
resolvedPath = fullfile(pwd, [name extension]);
clear cleanup
end

function resolvedPath = lexicalPath(filepath)
resolvedPath = char(labkit.app.internal.filesystem.absolutePath(filepath));
end

function tf = isDescendant(filepath, root)
separatorRoot = string(root);
if ~endsWith(separatorRoot, filesep)
    separatorRoot = separatorRoot + filesep;
end
if ispc
    tf = startsWith(lower(string(filepath)), lower(separatorRoot));
else
    tf = startsWith(string(filepath), separatorRoot);
end
end

function tf = isSamePath(left, right)
if ispc
    tf = strcmpi(char(left), char(right));
else
    tf = strcmp(char(left), char(right));
end
end
