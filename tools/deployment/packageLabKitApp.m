function result = packageLabKitApp(appSelector, zipFile, varargin)
%PACKAGELABKITAPP Create a standalone zip for one or more LabKit apps.
%
% Expected caller: LabKit launcher and maintainers preparing an app
% deployment bundle.
% Inputs:
%   appSelector app command/path/struct, or an array/cell collection of them.
%   zipFile     optional output zip path. Empty uses OutputRoot and a timestamp.
% Outputs:
%   result struct with zipFile, entryFiles, appCommands, packageRootName,
%          appRelativeFolders, visibilities, and fileCount.
% Options:
%   Root        LabKit source/runtime root. Defaults to the current repo root.
%   OutputRoot  default folder for generated zip files.
%   ProgressFcn function handle called as fcn(message, value), where value is 0..1.
%
% Examples:
%   addpath(fullfile("tools", "deployment"))
%   packageLabKitApp("labkit_CIC_app")
%   packageLabKitApp(["labkit_CIC_app", "labkit_EIS_app"])

    if nargin < 1
        appSelector = "";
    end
    if nargin < 2 || isempty(zipFile)
        zipFile = "";
    end

    opt = parsePackageOptions(varargin{:});
    root = char(canonicalPath(opt.Root));
    outputRoot = char(opt.OutputRoot);
    notifyProgress(opt.ProgressFcn, "Resolving app entry points...", 0.05);
    apps = resolvePackageApps(root, appSelector);

    validatePackageInputs(root, apps);
    if strlength(string(zipFile)) == 0
        zipFile = defaultZipFile(outputRoot, apps);
    end
    zipFile = char(absoluteOutputPath(zipFile));
    ensureFolder(fileparts(zipFile));

    packageRootName = packageFolderName(apps);
    stageParent = string(tempname);
    mkdir(stageParent);
    cleanup = onCleanup(@() removeFolderIfPresent(stageParent));
    packageRoot = fullfile(stageParent, packageRootName);
    mkdir(packageRoot);

    notifyProgress(opt.ProgressFcn, "Copying package support files...", 0.18);
    copyfile(fullfile(root, "labkit_launcher.m"), ...
        fullfile(packageRoot, "labkit_launcher.m"));
    copyRequiredToolFolder(root, packageRoot, "deployment");
    copyRequiredToolFolder(root, packageRoot, "profiling");

    notifyProgress(opt.ProgressFcn, "Copying LabKit library...", 0.30);
    copyfile(fullfile(root, "+labkit"), fullfile(packageRoot, "+labkit"));

    notifyProgress(opt.ProgressFcn, "Copying selected apps and assets...", 0.50);
    for k = 1:numel(apps)
        targetAppFolder = fullfile(packageRoot, apps(k).packageRelativeFolder);
        ensureFolder(fileparts(targetAppFolder));
        copyfile(apps(k).folder, targetAppFolder);
    end

    notifyProgress(opt.ProgressFcn, "Writing standalone entry files...", 0.65);
    entryFileNames = strings(numel(apps), 1);
    entryRelativeFiles = strings(numel(apps), 1);
    for k = 1:numel(apps)
        entryFileNames(k) = "run_" + string(apps(k).command) + ".m";
        entryRelativeFiles(k) = entryFileNames(k);
        writeText(fullfile(packageRoot, entryFileNames(k)), entryFileText(apps(k)));
    end
    writeText(fullfile(packageRoot, "README.txt"), ...
        readmeText(apps, entryRelativeFiles));
    notifyProgress(opt.ProgressFcn, "Creating zip package...", 0.85);
    if exist(zipFile, "file") == 2
        delete(zipFile);
    end
    zip(zipFile, char(packageRootName), char(stageParent));

    notifyProgress(opt.ProgressFcn, "Package complete.", 1.00);
    result = struct( ...
        "zipFile", string(zipFile), ...
        "packageRootName", packageRootName, ...
        "entryFiles", entryRelativeFiles, ...
        "appCommands", string({apps.command}).', ...
        "appRelativeFolders", string({apps.packageRelativeFolder}).', ...
        "visibilities", string({apps.visibility}).', ...
        "fileCount", numel(listFiles(packageRoot)));
    clear cleanup;
    removeFolderIfPresent(stageParent);
end

function opt = parsePackageOptions(varargin)
    p = inputParser;
    p.FunctionName = "packageLabKitApp";
    addParameter(p, "Root", repoRoot(), @isTextScalar);
    addParameter(p, "OutputRoot", fullfile(repoRoot(), "artifacts", "deployment"), @isTextScalar);
    addParameter(p, "ProgressFcn", [], @(value) isempty(value) || isa(value, "function_handle"));
    parse(p, varargin{:});
    opt = p.Results;
end

function apps = resolvePackageApps(root, selector)
    if isstruct(selector)
        template = struct("command", "", "folder", "", "entryFile", "", ...
            "packageRelativeFolder", "", "visibility", "");
        apps = repmat(template, 1, numel(selector));
        for k = 1:numel(selector)
            apps(k) = appFromLauncherStruct(root, selector(k));
        end
        apps = uniquePackageApps(apps);
        return;
    end

    if iscell(selector) || (isstring(selector) && ~isscalar(selector))
        selectors = string(selector);
        template = struct("command", "", "folder", "", "entryFile", "", ...
            "packageRelativeFolder", "", "visibility", "");
        apps = repmat(template, 1, numel(selectors));
        for k = 1:numel(selectors)
            apps(k) = resolvePackageApp(root, selectors(k));
        end
        apps = uniquePackageApps(apps);
        return;
    end

    apps = resolvePackageApp(root, selector);
end

function app = resolvePackageApp(root, selector)

    selectorText = string(selector);
    if strlength(strtrim(selectorText)) == 0
        error("packageLabKitApp:InvalidApp", ...
            "App selector must be an app command, entry file, app folder, or launcher app struct.");
    end

    if exist(selectorText, "dir") == 7
        entry = uniqueAppEntryInFolder(selectorText);
        app = appFromEntry(root, entry, "custom");
        return;
    end

    if exist(selectorText, "file") == 2
        app = appFromEntry(root, selectorText, "custom");
        return;
    end

    apps = discoverPackageApps(root);
    matches = apps(string({apps.command}) == selectorText);
    if isempty(matches)
        error("packageLabKitApp:AppNotFound", ...
            "No LabKit app entry point found for selector: %s", selectorText);
    elseif numel(matches) > 1
        error("packageLabKitApp:AmbiguousApp", ...
            "Multiple app entry points found for command: %s", selectorText);
    end
    app = matches;
end

function apps = uniquePackageApps(apps)
    if isempty(apps)
        error("packageLabKitApp:InvalidApp", ...
            "Select at least one LabKit app to package.");
    end
    commands = string({apps.command});
    [~, keep] = unique(commands, "stable");
    apps = apps(sort(keep));
end

function app = appFromLauncherStruct(root, raw)
    required = ["command", "folder"];
    for k = 1:numel(required)
        if ~isfield(raw, char(required(k)))
            error("packageLabKitApp:InvalidAppStruct", ...
                "Launcher app struct is missing field: %s", required(k));
        end
    end
    entryFile = fullfile(string(raw.folder), string(raw.command) + ".m");
    if isfield(raw, "visibility")
        visibility = string(raw.visibility);
    else
        visibility = "custom";
    end
    app = appFromEntry(root, entryFile, visibility);
end

function apps = discoverPackageApps(root)
    roots = appDiscoveryRoots(root);
    apps = emptyPackageApp();
    appCount = 0;
    for rootIndex = 1:numel(roots)
        appRoot = char(roots(rootIndex).appRoot);
        if exist(appRoot, "dir") ~= 7
            continue;
        end
        entries = appEntryFiles(appRoot);
        for k = 1:numel(entries)
            entryFile = string(fullfile(entries(k).folder, entries(k).name));
            rel = relativePath(appRoot, entryFile);
            if isHiddenImplementationPath(rel)
                continue;
            end
            appCount = appCount + 1;
            apps(appCount) = appFromEntry(root, entryFile, roots(rootIndex).visibility, roots(rootIndex).appRoot);
        end
    end
end

function app = appFromEntry(root, entryFile, visibility, appRoot)
    if nargin < 4
        appRoot = "";
    end
    entryFile = string(canonicalPath(entryFile));
    [folder, command, ext] = fileparts(entryFile);
    if string(ext) ~= ".m" || ...
            ~startsWith(string(command), "labkit_") || ~endsWith(string(command), "_app")
        error("packageLabKitApp:InvalidAppEntry", ...
            "App entry file must be named labkit_*_app.m: %s", entryFile);
    end
    if strlength(string(appRoot)) == 0
        appRoot = matchingAppRoot(root, folder);
    end
    packageRelativeFolder = packagedAppRelativeFolder(appRoot, folder, visibility);
    app = struct( ...
        "command", char(command), ...
        "folder", char(folder), ...
        "entryFile", char(entryFile), ...
        "packageRelativeFolder", char(packageRelativeFolder), ...
        "visibility", char(visibility));
end

function app = emptyPackageApp()
    app = struct("command", {}, "folder", {}, "entryFile", {}, ...
        "packageRelativeFolder", {}, "visibility", {});
end

function entries = appEntryFiles(appRoot)
    entries = dir(fullfile(appRoot, "**", "labkit_*_app.m"));
    entries = entries(~[entries.isdir]);
    if isempty(entries)
        return;
    end
    paths = strings(numel(entries), 1);
    commands = strings(numel(entries), 1);
    for k = 1:numel(entries)
        paths(k) = string(fullfile(entries(k).folder, entries(k).name));
        [~, commands(k)] = fileparts(paths(k));
    end
    [~, order] = sortrows([commands, paths]);
    entries = entries(order);
    commands = commands(order);
    [~, keep] = unique(commands, "stable");
    entries = entries(keep);
end

function roots = appDiscoveryRoots(root)
    privateRoots = privateAppRoots(root);
    roots = repmat(struct("appRoot", "", "visibility", ""), ...
        1, numel(privateRoots) + 1);
    roots(1) = struct("appRoot", string(fullfile(root, "apps")), ...
        "visibility", "public");
    for k = 1:numel(privateRoots)
        roots(k + 1) = struct( ...
            "appRoot", privateRoots(k), "visibility", "private");
    end
end

function roots = privateAppRoots(root)
    candidates = strings(numel(strsplit(char(string(getenv( ...
        "LABKIT_PRIVATE_APP_ROOTS"))), pathsep)) + 1, 1);
    candidateCount = 0;
    localRoot = string(fullfile(root, "private_apps", "apps"));
    if exist(localRoot, "dir") == 7
        candidateCount = candidateCount + 1;
        candidates(candidateCount) = localRoot;
    end

    envValue = string(getenv("LABKIT_PRIVATE_APP_ROOTS"));
    if strlength(strtrim(envValue)) > 0
        parts = string(strsplit(char(envValue), pathsep));
        parts = strip(parts);
        parts = parts(strlength(parts) > 0);
        for k = 1:numel(parts)
            candidate = privateAppRootAppsFolder(parts(k));
            if exist(candidate, "dir") == 7
                candidateCount = candidateCount + 1;
                candidates(candidateCount) = candidate;
            end
        end
    end
    roots = unique(candidates(1:candidateCount), "stable");
end

function appRoot = privateAppRootAppsFolder(root)
    root = string(root);
    if endsWith(strrep(root, "\", "/"), "/apps")
        appRoot = root;
    else
        appRoot = string(fullfile(root, "apps"));
    end
end

function appRoot = matchingAppRoot(root, appFolder)
    roots = appDiscoveryRoots(root);
    appFolder = string(canonicalPath(appFolder));
    for k = 1:numel(roots)
        candidate = string(canonicalPath(roots(k).appRoot));
        if appFolder == candidate || startsWith(appFolder, candidate + filesep)
            appRoot = candidate;
            return;
        end
    end
    appRoot = string(fileparts(appFolder));
end

function rel = packagedAppRelativeFolder(appRoot, appFolder, visibility)
    appRoot = string(canonicalPath(appRoot));
    appFolder = string(canonicalPath(appFolder));
    if appFolder == appRoot
        tail = string(getFolderName(appFolder));
    else
        tail = string(relativePath(appRoot, appFolder));
    end
    if string(visibility) == "private"
        rel = string(fullfile("private_apps", "apps", tail));
    else
        rel = string(fullfile("apps", tail));
    end
end

function entryFile = uniqueAppEntryInFolder(folder)
    entries = appEntryFiles(folder);
    if isempty(entries)
        error("packageLabKitApp:AppNotFound", ...
            "No labkit_*_app.m entry point found in folder: %s", folder);
    elseif numel(entries) > 1
        error("packageLabKitApp:AmbiguousApp", ...
            "Multiple labkit_*_app entry points found in folder: %s", folder);
    end
    entryFile = string(fullfile(entries(1).folder, entries(1).name));
end

function validatePackageInputs(root, app)
    if exist(fullfile(root, "labkit_launcher.m"), "file") ~= 2
        error("packageLabKitApp:MissingLauncher", ...
            "Cannot package app because labkit_launcher.m was not found under: %s", root);
    end
    if exist(fullfile(root, "+labkit"), "dir") ~= 7
        error("packageLabKitApp:MissingLabKit", ...
            "Cannot package app because +labkit was not found under: %s", root);
    end
    requiredToolFolders = ["deployment", "profiling"];
    for k = 1:numel(requiredToolFolders)
        toolFolder = fullfile(root, "tools", requiredToolFolders(k));
        if exist(toolFolder, "dir") ~= 7
            error("packageLabKitApp:MissingTool", ...
                "Cannot package app because %s was not found.", toolFolder);
        end
    end
    for k = 1:numel(app)
        if exist(app(k).folder, "dir") ~= 7 || exist(app(k).entryFile, "file") ~= 2
            error("packageLabKitApp:MissingApp", ...
                "Cannot package app because its entry file was not found: %s", app(k).entryFile);
        end
        validateSourceFilesAvailable(root, app(k));
    end
end

function validateSourceFilesAvailable(root, app)
    [entryFolder, entryName] = fileparts(app.entryFile);
    requiredSources = [
        string(fullfile(root, "labkit_launcher.m"))
        string(fullfile(entryFolder, entryName + ".m"))
        string(fullfile(root, "tools", "deployment", "packageLabKitApp.m"))
        string(fullfile(root, "tools", "profiling", "profileLabKitTarget.m"))];
    missing = requiredSources(arrayfun( ...
        @(path) exist(path, "file") ~= 2, requiredSources));
    if ~isempty(missing)
        error("packageLabKitApp:SourceUnavailable", ...
            "Source packaging requires MATLAB source files. Missing: %s", ...
            strjoin(cellstr(missing), ", "));
    end
end

function copyRequiredToolFolder(root, packageRoot, toolName)
    source = fullfile(root, "tools", toolName);
    target = fullfile(packageRoot, "tools", toolName);
    ensureFolder(fileparts(target));
    copyfile(source, target);
end

function text = entryFileText(app)
    text = sprintf([ ...
        'function varargout = run_%1$s(varargin)\n' ...
        '%%RUN_%2$s Standalone entry point for %1$s.\n' ...
        'root = fileparts(mfilename(''fullpath''));\n' ...
        'addPathIfMissing(root);\n' ...
        'addPathIfMissing(fullfile(root, ''apps''), ''-end'');\n' ...
        'addPathIfMissing(fullfile(root, ''%3$s''), ''-end'');\n' ...
        'if nargout > 0\n' ...
        '    [varargout{1:nargout}] = %1$s(varargin{:});\n' ...
        'else\n' ...
        '    %1$s(varargin{:});\n' ...
        'end\n' ...
        'end\n\n' ...
        'function addPathIfMissing(folder, varargin)\n' ...
        'if exist(folder, ''dir'') == 7 && ~any(strcmp(strsplit(path, pathsep), char(folder)))\n' ...
        '    addpath(folder, varargin{:});\n' ...
        'end\n' ...
        'end\n'], ...
        app.command, upper(app.command), strrep(app.packageRelativeFolder, "\", "/"));
end

function text = readmeText(apps, entryFileNames)
    appCount = numel(apps);
    commandLines = strings(appCount, 1);
    for k = 1:appCount
        commandLines(k) = sprintf("- %s: %s", apps(k).command, ...
            erase(entryFileNames(k), ".m"));
    end
    contentsLine = ['This package intentionally includes only the selected app folders, the LabKit launcher, ' ...
        'selected launcher tools, and the shared +labkit library.'];
    launcherLines = sprintf([ ...
        '\n' ...
        'You can also start from the packaged launcher by running:\n' ...
        'labkit_launcher\n']);
    text = sprintf([ ...
        'LabKit app package\n' ...
        '\n' ...
        'Apps: %d\n' ...
        'To run an app, unzip the package, open MATLAB in this folder, and run one entry:\n' ...
        '%s\n' ...
        '\n' ...
        '%s' ...
        '%s\n'], ...
        appCount, strjoin(commandLines, newline), ...
        launcherLines, contentsLine);
end

function zipFile = defaultZipFile(outputRoot, apps)
    timestamp = string(datetime("now", "Format", "yyyyMMdd_HHmmss"));
    zipFile = fullfile(outputRoot, packageFolderName(apps) + "_" + timestamp + ".zip");
end

function name = packageFolderName(apps)
    if isscalar(apps)
        name = "LabKitApp_" + sanitizeFilename(apps.command);
    else
        name = "LabKitApps_" + string(numel(apps));
    end
end

function out = absoluteOutputPath(out)
    out = string(out);
    if strlength(out) == 0
        return;
    end
    if isAbsolutePath(out)
        return;
    end
    out = string(fullfile(pwd, out));
end

function tf = isAbsolutePath(filepath)
    filepath = char(filepath);
    if ispc
        tf = ~isempty(regexp(filepath, '^[A-Za-z]:[\\/]', 'once')) || startsWith(filepath, "\\");
    else
        tf = startsWith(filepath, filesep);
    end
end

function files = listFiles(root)
    entries = dir(fullfile(root, "**", "*"));
    entries = entries(~[entries.isdir]);
    files = string(fullfile({entries.folder}, {entries.name}));
end

function tf = isHiddenImplementationPath(rel)
    parts = split(string(strrep(rel, filesep, "/")), "/");
    tf = any(startsWith(parts, "+")) || any(parts == "private");
end

function notifyProgress(progressFcn, message, value)
    if isempty(progressFcn)
        return;
    end
    try
        progressFcn(string(message), value);
    catch
    end
end

function writeText(filepath, text)
    ensureFolder(fileparts(filepath));
    fid = fopen(filepath, "w");
    assert(fid > 0, "Could not write file: %s", filepath);
    cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, "%s", text);
    clear cleanup;
end

function ensureFolder(folder)
    if strlength(string(folder)) > 0 && exist(folder, "dir") ~= 7
        mkdir(folder);
    end
end

function removeFolderIfPresent(folder)
    if exist(folder, "dir") == 7
        rmdir(folder, "s");
    end
end

function root = repoRoot()
    root = fileparts(fileparts(fileparts(mfilename("fullpath"))));
end

function resolvedPath = canonicalPath(filepath)
    resolvedPath = labkit.app.internal.filesystem.absolutePath(filepath);
    if ispc
        resolvedPath = lower(resolvedPath);
    end
    resolvedPath = char(resolvedPath);
end

function rel = relativePath(root, filepath)
    rel = char(filepath);
    prefix = [char(root) filesep];
    if startsWith(rel, prefix)
        rel = rel(numel(prefix)+1:end);
    end
    rel = strrep(rel, filesep, "/");
end

function name = getFolderName(folder)
    [~, name] = fileparts(folder);
end

function name = sanitizeFilename(value)
    name = regexprep(char(string(value)), '[^A-Za-z0-9._-]', '-');
    if isempty(name)
        name = "labkit-app";
    end
end

function tf = isTextScalar(value)
    tf = (ischar(value) && (isrow(value) || isempty(value))) || ...
        (isstring(value) && isscalar(value));
end
