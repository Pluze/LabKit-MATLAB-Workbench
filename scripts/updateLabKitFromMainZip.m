% Script helper. Expected caller: labkit_launcher or manual maintenance from
% the repository root. Inputs are optional name-value settings. Output is a
% summary struct. Side effects: downloads GitHub main.zip, backs up only
% LabKit-managed files that will be changed, overlays managed files into the
% current install root, and writes .labkit-managed-files.txt.
function result = updateLabKitFromMainZip(varargin)
%UPDATELABKITFROMMAINZIP Overlay the latest GitHub main zip into this install.

    p = inputParser;
    p.FunctionName = "updateLabKitFromMainZip";
    p.addParameter("Root", defaultRoot(), @isTextScalar);
    p.addParameter("SourceUrl", ...
        "https://github.com/Pluze/LabKit-MATLAB-Workbench/archive/refs/heads/main.zip", ...
        @isTextScalar);
    p.addParameter("Confirm", true, @(v) islogical(v) && isscalar(v));
    p.addParameter("TempRoot", "", @isTextScalar);
    p.parse(varargin{:});

    root = char(string(p.Results.Root));
    sourceUrl = char(string(p.Results.SourceUrl));
    tempRoot = tempRootPath(p.Results.TempRoot);
    cleanup = onCleanup(@() removeFolderIfPresent(tempRoot));

    assertInstallRoot(root);
    assertNotGitCheckout(root);
    if p.Results.Confirm && ~confirmUpdate(root)
        result = summaryStruct(root, "", 0, 0, "Update canceled.");
        return;
    end

    ensureFolder(tempRoot);
    zipPath = fullfile(tempRoot, "main.zip");
    extractRoot = fullfile(tempRoot, "extracted");
    fetchZip(sourceUrl, zipPath);
    unzip(char(zipPath), char(extractRoot));
    sourceRoot = findExtractedProjectRoot(extractRoot);
    assertInstallRoot(sourceRoot);

    newFiles = collectManagedFiles(sourceRoot);
    oldFiles = readManifest(root);
    backupPath = createBackup(root, tempRoot, newFiles, oldFiles);
    copiedCount = overlayManagedFiles(sourceRoot, root, newFiles);
    deletedCount = deleteStaleManagedFiles(root, oldFiles, newFiles);
    writeManifest(root, newFiles);

    result = summaryStruct(root, backupPath, copiedCount, deletedCount, ...
        sprintf(['Updated from GitHub main. Copied %d file(s), removed %d ' ...
        'retired managed file(s). Restart labkit_launcher. Backup: %s'], ...
        copiedCount, deletedCount, backupPath));
    clear cleanup;
    removeFolderIfPresent(tempRoot);
end

function root = defaultRoot()
    root = fileparts(fileparts(mfilename('fullpath')));
end

function tempRoot = tempRootPath(value)
    if strlength(string(value)) == 0
        tempRoot = tempname;
    else
        tempRoot = char(string(value));
    end
end

function assertInstallRoot(root)
    if exist(fullfile(root, "labkit_launcher.m"), "file") ~= 2 || ...
            exist(fullfile(root, "+labkit"), "dir") ~= 7 || ...
            exist(fullfile(root, "apps"), "dir") ~= 7
        error("updateLabKitFromMainZip:InvalidRoot", ...
            "Folder is not a LabKit install root: %s", root);
    end
end

function assertNotGitCheckout(root)
    if exist(fullfile(root, ".git"), "dir") == 7
        error("updateLabKitFromMainZip:GitCheckout", ...
            "Update from GitHub zip is disabled for git checkouts. " + ...
            "Use git to sync this working tree.");
    end
end

function tf = confirmUpdate(root)
    message = sprintf(['Download the latest GitHub main zip and overwrite ' ...
        'LabKit-managed files in:\n\n%s\n\nUser files that are not LabKit ' ...
        'project files will be left in place.'], root);
    try
        choice = questdlg(message, "Update LabKit", "Update", "Cancel", ...
            "Cancel");
        tf = strcmp(choice, "Update");
    catch
        tf = false;
    end
end

function fetchZip(sourceUrl, zipPath)
    if exist(sourceUrl, "file") == 2
        copyfile(sourceUrl, zipPath);
    else
        websave(zipPath, sourceUrl);
    end
end

function sourceRoot = findExtractedProjectRoot(extractRoot)
    entries = dir(extractRoot);
    entries = entries([entries.isdir]);
    names = string({entries.name});
    entries = entries(~ismember(names, [".", ".."]));
    for k = 1:numel(entries)
        candidate = fullfile(entries(k).folder, entries(k).name);
        if exist(fullfile(candidate, "labkit_launcher.m"), "file") == 2
            sourceRoot = candidate;
            return;
        end
    end
    error("updateLabKitFromMainZip:InvalidZip", ...
        "Downloaded zip did not contain a LabKit project root.");
end

function files = collectManagedFiles(root)
    entries = dir(fullfile(root, "**", "*"));
    files = strings(1, 0);
    for k = 1:numel(entries)
        if entries(k).isdir
            continue;
        end
        rel = relativePath(root, fullfile(entries(k).folder, entries(k).name));
        if isManagedRelativePath(rel)
            files(end+1) = string(rel);
        end
    end
    files = sort(unique(files));
end

function files = collectRelativeFiles(root)
    entries = dir(fullfile(root, "**", "*"));
    files = strings(1, 0);
    for k = 1:numel(entries)
        if entries(k).isdir
            continue;
        end
        files(end+1) = string(relativePath(root, ...
            fullfile(entries(k).folder, entries(k).name)));
    end
    files = sort(unique(files));
end

function tf = isManagedRelativePath(rel)
    parts = split(string(strrep(rel, filesep, "/")), "/");
    first = parts(1);
    rootFiles = ["AGENTS.md", "LICENSE", "README.md", "buildfile.m", ...
        "labkit_launcher.m", ".gitignore"];
    managedRoots = ["+labkit", "apps", "docs", "scripts", "tests", ...
        ".agents", ".github"];
    tf = ismember(string(rel), rootFiles) || ismember(first, managedRoots);
end

function backupPath = createBackup(root, tempRoot, newFiles, oldFiles)
    backupFiles = filesToBackup(root, newFiles, oldFiles);
    timestamp = char(datetime("now", "Format", "yyyyMMdd-HHmmss"));
    backupName = sprintf("LabKit-backup-%s.zip", timestamp);
    backupPath = fullfile(root, backupName);
    staging = fullfile(tempRoot, "backup-staging");
    ensureFolder(staging);
    writeText(fullfile(staging, "README_RESTORE.txt"), ...
        ["This zip contains LabKit-managed files overwritten or removed " ...
        "during an update." newline ...
        "To restore, unzip it over the LabKit install folder." newline]);

    for k = 1:numel(backupFiles)
        source = fullfile(root, char(backupFiles(k)));
        if exist(source, "file") ~= 2
            continue;
        end
        target = fullfile(staging, char(backupFiles(k)));
        ensureFolder(fileparts(target));
        copyfile(source, target);
    end
    zipFiles = collectRelativeFiles(staging);
    zip(char(backupPath), cellstr(zipFiles), char(staging));
end

function files = filesToBackup(root, newFiles, oldFiles)
    manifest = manifestPath(root);
    changed = newFiles(arrayfun(@(f) exist(fullfile(root, char(f)), ...
        "file") == 2, newFiles));
    stale = setdiff(oldFiles, newFiles);
    files = unique([changed(:); stale(:)]);
    if exist(manifest, "file") == 2
        files(end+1) = string(relativePath(root, manifest));
    end
    files = sort(unique(files));
end

function copiedCount = overlayManagedFiles(sourceRoot, root, files)
    copiedCount = 0;
    for k = 1:numel(files)
        rel = char(files(k));
        source = fullfile(sourceRoot, rel);
        target = fullfile(root, rel);
        ensureFolder(fileparts(target));
        copyfile(source, target, "f");
        copiedCount = copiedCount + 1;
    end
end

function deletedCount = deleteStaleManagedFiles(root, oldFiles, newFiles)
    stale = setdiff(oldFiles, newFiles);
    deletedCount = 0;
    for k = 1:numel(stale)
        target = fullfile(root, char(stale(k)));
        if exist(target, "file") == 2
            delete(target);
            deletedCount = deletedCount + 1;
            removeEmptyParents(root, fileparts(target));
        end
    end
end

function removeEmptyParents(root, folder)
    while startsWith(folder, root) && ~strcmp(folder, root)
        entries = dir(folder);
        names = string({entries.name});
        if any(~ismember(names, [".", ".."]))
            return;
        end
        parent = fileparts(folder);
        rmdir(folder);
        folder = parent;
    end
end

function files = readManifest(root)
    path = manifestPath(root);
    if exist(path, "file") ~= 2
        files = strings(1, 0);
        return;
    end
    files = string(readlines(path)).';
    files = files(strlength(strtrim(files)) > 0);
    files = sort(unique(strtrim(files)));
end

function writeManifest(root, files)
    writeText(manifestPath(root), strjoin(cellstr(files), newline) + newline);
end

function path = manifestPath(root)
    path = fullfile(root, ".labkit-managed-files.txt");
end

function result = summaryStruct(root, backupPath, copiedCount, deletedCount, message)
    result = struct( ...
        "root", string(root), ...
        "backupZip", string(backupPath), ...
        "copiedCount", copiedCount, ...
        "deletedCount", deletedCount, ...
        "message", string(message));
end

function ensureFolder(folder)
    if strlength(string(folder)) > 0 && exist(folder, "dir") ~= 7
        mkdir(folder);
    end
end

function writeText(path, text)
    fid = fopen(path, "w");
    assert(fid > 0, "Could not write file: %s", path);
    cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, "%s", text);
    clear cleanup;
end

function removeFolderIfPresent(folder)
    if strlength(string(folder)) > 0 && exist(folder, "dir") == 7
        rmdir(folder, "s");
    end
end

function tf = isTextScalar(value)
    tf = ischar(value) || (isstring(value) && isscalar(value));
end

function rel = relativePath(root, filepath)
    rel = char(filepath);
    prefix = [char(root) filesep];
    if startsWith(rel, prefix)
        rel = rel(numel(prefix)+1:end);
    end
    rel = strrep(rel, filesep, "/");
end
