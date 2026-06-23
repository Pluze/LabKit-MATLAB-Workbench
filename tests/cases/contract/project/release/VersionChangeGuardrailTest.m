classdef VersionChangeGuardrailTest < matlab.unittest.TestCase
    %VERSIONCHANGEGUARDRAILTEST Guard versioned code against stale versions.

    methods (Test, TestTags = {'Integration', 'Style'})
        function changedVersionedCodeBumpsVersion(testCase)
            root = setupLabKitTestPath();
            issues = changedVersionedCodeWithoutVersionBump(root);

            testCase.verifyEmpty(issues, ...
                "Versioned code changed without a valid increasing semver bump: " + ...
                strjoin(issues, ", "));
        end
    end
end

function issues = changedVersionedCodeWithoutVersionBump(root)
    changeSet = gitChangeSet(root);
    artifacts = versionedArtifactsForPaths(root, changeSet.paths);
    issues = strings(1, 0);

    for k = 1:numel(artifacts)
        artifact = artifacts(k);
        currentVersion = versionInWorkingTree(root, artifact.versionPath);
        baseVersion = versionInGit(root, changeSet.baseRef, artifact.versionPath);
        if strlength(currentVersion) == 0
            issues(end+1) = artifact.label + " missing " + artifact.versionPath;
        elseif ~isSemver(currentVersion)
            issues(end+1) = artifact.label + " invalid semver " + currentVersion;
        elseif strlength(baseVersion) > 0 && ~isSemver(baseVersion)
            issues(end+1) = artifact.label + " base version invalid " + baseVersion;
        elseif strlength(baseVersion) > 0 && compareSemver(currentVersion, baseVersion) <= 0
            issues(end+1) = artifact.label + " " + currentVersion + ...
                " must be greater than " + baseVersion;
        end
    end
    issues = unique(issues, "stable");
end

function changeSet = gitChangeSet(root)
    changeSet = struct("baseRef", "HEAD", "paths", strings(1, 0));
    if ~isGitCheckout(root)
        return;
    end

    paths = [gitChangedPaths(root, "HEAD"), gitUntrackedPaths(root)];
    if isempty(paths) && gitRefExists(root, "HEAD^")
        changeSet.baseRef = "HEAD^";
        paths = gitChangedPaths(root, changeSet.baseRef);
    end
    changeSet.paths = unique(paths, "stable");
end

function artifacts = versionedArtifactsForPaths(root, paths)
    artifacts = emptyArtifacts();
    for k = 1:numel(paths)
        artifact = versionedArtifactForPath(root, paths(k));
        if strlength(artifact.label) > 0
            artifacts(end+1) = artifact;
        end
    end
    artifacts = uniqueArtifacts(artifacts);
end

function artifact = versionedArtifactForPath(root, path)
    path = normalizePath(path);
    artifact = emptyArtifact();
    if ~endsWith(path, ".m")
        return;
    end

    if path == "labkit_launcher.m"
        artifact = makeArtifact("labkit_launcher", "labkit_launcher.m");
        return;
    end

    parts = split(path, "/");
    if numel(parts) >= 2 && parts(1) == "+labkit"
        facade = erase(parts(2), "+");
        versionPath = "+labkit/+" + facade + "/version.m";
        if facadeHasVersion(root, versionPath)
            artifact = makeArtifact("labkit." + facade, versionPath);
        end
        return;
    end

    if numel(parts) >= 3 && parts(1) == "apps"
        appRoot = strjoin(parts(1:3), "/");
        appSlug = parts(3);
        versionPath = appRoot + "/+" + appSlug + "/version.m";
        artifact = makeArtifact(appRoot, versionPath);
    end
end

function tf = facadeHasVersion(root, versionPath)
    parts = [{char(root)}; cellstr(split(string(versionPath), "/"))];
    tf = exist(fullfile(parts{:}), "file") == 2;
end

function artifact = makeArtifact(label, versionPath)
    artifact = struct("label", string(label), "versionPath", string(versionPath));
end

function artifact = emptyArtifact()
    artifact = makeArtifact("", "");
end

function artifacts = emptyArtifacts()
    artifacts = repmat(emptyArtifact(), 1, 0);
end

function artifacts = uniqueArtifacts(artifacts)
    if isempty(artifacts)
        return;
    end
    signatures = [artifacts.versionPath];
    [~, keep] = unique(signatures, "stable");
    artifacts = artifacts(keep);
end

function version = versionInWorkingTree(root, relPath)
    parts = [{char(root)}; cellstr(split(string(relPath), "/"))];
    filepath = fullfile(parts{:});
    if exist(filepath, "file") ~= 2
        version = "";
        return;
    end
    version = versionInText(string(fileread(filepath)));
end

function version = versionInGit(root, ref, relPath)
    command = gitCommand(root, "show " + ...
        shellDoubleQuote(validateGitRef(ref) + ":" + normalizePath(relPath)));
    [status, output] = system(char(command));
    if status ~= 0
        version = "";
        return;
    end
    version = versionInText(string(output));
end

function version = versionInText(text)
    version = regexp(text, '["'']version["'']\s*,\s*["'']([^"'']+)["'']', ...
        "tokens", "once");
    if isempty(version)
        version = regexp(text, ...
            'versionInfo\([^,]+,\s*["'']([^"'']+)["'']', ...
            "tokens", "once");
    end
    if isempty(version)
        version = "";
    else
        version = string(version{1});
    end
end

function tf = isSemver(version)
    tf = ~isempty(regexp(char(version), '^\d+\.\d+\.\d+$', 'once'));
end

function result = compareSemver(left, right)
    leftParts = sscanf(char(left), '%d.%d.%d').';
    rightParts = sscanf(char(right), '%d.%d.%d').';
    result = 0;
    for k = 1:3
        if leftParts(k) > rightParts(k)
            result = 1;
            return;
        elseif leftParts(k) < rightParts(k)
            result = -1;
            return;
        end
    end
end

function tf = isGitCheckout(root)
    command = gitCommand(root, "rev-parse --is-inside-work-tree");
    [status, output] = system(char(command));
    tf = status == 0 && strip(string(output)) == "true";
end

function paths = gitChangedPaths(root, baseRef)
    command = gitCommand(root, "diff --name-only --diff-filter=ACMRTUXB " + ...
        shellDoubleQuote(validateGitRef(baseRef)));
    paths = runGitPathCommand(command);
end

function paths = gitUntrackedPaths(root)
    command = gitCommand(root, "ls-files --others --exclude-standard");
    paths = runGitPathCommand(command);
end

function tf = gitRefExists(root, ref)
    command = gitCommand(root, "rev-parse --verify --quiet " + ...
        shellDoubleQuote(validateGitRef(ref)));
    [status, ~] = system(char(command));
    tf = status == 0;
end

function paths = runGitPathCommand(command)
    [status, output] = system(char(command));
    if status ~= 0
        paths = strings(1, 0);
        return;
    end
    paths = splitlines(string(output));
    paths = strip(replace(paths, "\", "/"));
    paths = paths(strlength(paths) > 0).';
end

function path = normalizePath(path)
    path = strip(replace(string(path), "\", "/"));
    while startsWith(path, "./")
        path = extractAfter(path, 2);
    end
end

function ref = validateGitRef(ref)
    ref = string(ref);
    chars = char(ref);
    allowedRefChars = './_@{}^-~';
    allowed = isstrprop(chars, "alphanum") | ismember(chars, allowedRefChars);
    if ~isscalar(ref) || strlength(ref) == 0 || ~all(allowed)
        error("LabKit:Tests:InvalidGitRef", ...
            "Version guardrail git ref contains unsupported shell characters.");
    end
end

function command = gitCommand(root, arguments)
    command = "git --no-pager -c core.fsmonitor=false " + ...
        "-c credential.helper= -c core.askPass= -C " + ...
        shellDoubleQuote(root) + " " + arguments;
end

function quoted = shellDoubleQuote(value)
    quoted = string(value);
    if contains(quoted, """")
        error("LabKit:Tests:InvalidShellValue", ...
            "Shell-quoted values cannot contain double-quote characters.");
    end
    quoted = """" + quoted + """";
end
