classdef VersionManagementSpec < matlab.unittest.TestCase
    methods (Test, TestTags = {'Contract:system', 'Env:headless'})
        function gitFilesAndDirectoriesRejectEveryInstallModeBeforeNetwork(testCase)
            modes = ["main", "stable", "install"];
            for gitKind = ["file", "directory"]
                root = fixtureRoot(testCase, "old");
                if gitKind == "file"
                    writeText(fullfile(root, ".git"), "gitdir: synthetic-worktree");
                else
                    mkdir(fullfile(root, ".git"));
                end
                [networkFolder, networkCleanup] = networkStubs(testCase);
                toolCleanup = isolatedTool(networkFolder);
                for mode = modes
                    sourceArgs = {};
                    if mode == "install", sourceArgs = {"Source", selectedSource()}; end
                    testCase.verifyError(@() manageLabKitVersions(root, mode, sourceArgs{:}), ...
                        "LabKit:Deployment:GitCheckout");
                    testCase.verifyFalse(isappdata(groot, "versionToolWebreadCount"));
                    testCase.verifyFalse(isappdata(groot, "versionToolWebsaveCalled"));
                end
                delete(toolCleanup); delete(networkCleanup)
            end
        end

        function invalidRootRejectsBeforeAnyNetworkRequest(testCase)
            root = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            [networkFolder, networkCleanup] = networkStubs(testCase);
            toolCleanup = isolatedTool(networkFolder);

            testCase.verifyError(@() manageLabKitVersions(root, "main"), ...
                "LabKit:Deployment:InvalidRoot");
            testCase.verifyFalse(isappdata(groot, "versionToolWebreadCount"));
            testCase.verifyFalse(isappdata(groot, "versionToolWebsaveCalled"));
            delete(toolCleanup); delete(networkCleanup)
        end

        function selectedCandidateMigratesLocalDataAndRetainsSiblingBackup(testCase)
            root = fixtureRoot(testCase, "old");
            candidate = fixtureCandidate(testCase, "new");
            toolCleanup = isolatedTool("");
            writeAllLocalSentinels(root);
            cleanup = setHook(struct("CandidateRoot", candidate, "Confirm", true));

            result = manageLabKitVersions(root, "install", "Source", selectedSource());

            testCase.verifyTrue(result.updated);
            testCase.verifyEqual(readMarker(root), "new");
            verifyAllLocalSentinels(testCase, root);
            testCase.verifyTrue(result.backupRetained);
            testCase.verifyEqual(readMarker(result.backupFolder), "old");
            delete(cleanup); delete(toolCleanup)
        end

        function installationWithoutLocalDataDeletesTheSiblingBackup(testCase)
            root = fixtureRoot(testCase, "old");
            candidate = fixtureCandidate(testCase, "new");
            toolCleanup = isolatedTool("");
            cleanup = setHook(struct("CandidateRoot", candidate, "Confirm", true));

            result = manageLabKitVersions(root, "install", "Source", selectedSource());

            testCase.verifyTrue(result.updated);
            testCase.verifyFalse(result.backupRetained);
            testCase.verifyEmpty(dir(fullfile(fileparts(root), "*.version-backup-*")));
            delete(cleanup); delete(toolCleanup)
        end

        function replacementAndRollbackRestoreOnlyValidRootPathSubtrees(testCase)
            root = fixtureRoot(testCase, "old");
            candidate = fixtureCandidate(testCase, "new");
            toolCleanup = isolatedTool("");
            mkdir(fullfile(root, "apps", "retained"));
            mkdir(fullfile(root, "tools", "retired"));
            mkdir(fullfile(candidate, "apps", "retained"));
            addpath(root, "-begin");
            addpath(fullfile(root, "apps", "retained"), "-begin");
            addpath(fullfile(root, "tools", "retired"), "-begin");
            cleanup = setHook(struct("CandidateRoot", candidate, "Confirm", true));

            manageLabKitVersions(root, "install", "Source", selectedSource());

            entries = normalizedPathEntries();
            testCase.verifyTrue(any(entries == normalizedPath(root)));
            testCase.verifyTrue(any(entries == normalizedPath(fullfile(root, "apps", "retained"))));
            testCase.verifyFalse(any(entries == normalizedPath(fullfile(root, "tools", "retired"))));
            testCase.verifyFalse(any(contains(entries, ".version-backup-")));
            delete(cleanup);

            rollbackRoot = fixtureRoot(testCase, "rollback-old");
            rollbackCandidate = fixtureCandidate(testCase, "rollback-new");
            mkdir(fullfile(rollbackRoot, "apps", "retained"));
            mkdir(fullfile(rollbackRoot, "tools", "restored"));
            mkdir(fullfile(rollbackCandidate, "apps", "retained"));
            addpath(rollbackRoot, "-begin");
            addpath(fullfile(rollbackRoot, "apps", "retained"), "-begin");
            addpath(fullfile(rollbackRoot, "tools", "restored"), "-begin");
            cleanup = setHook(struct( ...
                "CandidateRoot", rollbackCandidate, ...
                "Confirm", true, ...
                "FailAfterBackup", true));
            testCase.verifyError(@() manageLabKitVersions( ...
                rollbackRoot, "install", "Source", selectedSource()), ...
                "LabKit:Deployment:InjectedFailure");
            entries = normalizedPathEntries();
            testCase.verifyEqual(readMarker(rollbackRoot), "rollback-old");
            testCase.verifyTrue(any(entries == normalizedPath(rollbackRoot)));
            testCase.verifyTrue(any(entries == normalizedPath( ...
                fullfile(rollbackRoot, "apps", "retained"))));
            testCase.verifyTrue(any(entries == normalizedPath( ...
                fullfile(rollbackRoot, "tools", "restored"))));
            testCase.verifyFalse(any(contains(entries, ".version-backup-")));
            delete(cleanup); delete(toolCleanup)
        end

        function cancelDoesNotDownload(testCase)
            root = fixtureRoot(testCase, "old");
            [networkFolder, networkCleanup] = networkStubs(testCase);
            toolCleanup = isolatedTool(networkFolder);
            cleanup = setHook(struct("Confirm", false));

            result = manageLabKitVersions(root, "main");

            testCase.verifyFalse(result.updated);
            testCase.verifyFalse(isappdata(groot, "versionToolWebsaveCalled"));
            delete(cleanup); delete(toolCleanup); delete(networkCleanup)
        end

        function selectedSourceRejectsExternalArchiveUrls(testCase)
            root = fixtureRoot(testCase, "old");
            toolCleanup = isolatedTool("");
            source = selectedSource();
            source.Url = "https://invalid.example/synthetic.zip";

            testCase.verifyError(@() manageLabKitVersions( ...
                root, "install", "Source", source), ...
                "LabKit:Deployment:InvalidSource");
            testCase.verifyEqual(readMarker(root), "old");
            delete(toolCleanup)
        end

        function invalidAndNestedCandidatesAreRejected(testCase)
            root = fixtureRoot(testCase, "old");
            toolCleanup = isolatedTool("");
            invalid = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            cleanup = setHook(struct("CandidateRoot", invalid, "Confirm", true));
            testCase.verifyError(@() manageLabKitVersions(root, "install", "Source", selectedSource()), "LabKit:Deployment:InvalidCandidate");
            delete(cleanup)
            nested = fullfile(root, "candidate");
            createCandidate(nested, "nested");
            cleanup = setHook(struct("CandidateRoot", nested, "Confirm", true));
            testCase.verifyError(@() manageLabKitVersions(root, "install", "Source", selectedSource()), "LabKit:Deployment:InvalidCandidate");
            delete(cleanup)
            outer = fixtureCandidate(testCase, "outer");
            nestedRoot = fullfile(outer, "nested-root");
            createRoot(nestedRoot, "nested-old");
            cleanup = setHook(struct("CandidateRoot", outer, "Confirm", true));
            testCase.verifyError(@() manageLabKitVersions(nestedRoot, "install", "Source", selectedSource()), "LabKit:Deployment:InvalidCandidate");
            delete(cleanup); delete(toolCleanup)
        end

        function candidateConflictAndInjectedFailureRollbackWithoutStalePaths(testCase)
            root = fixtureRoot(testCase, "old");
            candidate = fixtureCandidate(testCase, "new");
            toolCleanup = isolatedTool("");
            writeText(fullfile(root, "photos", "sentinel.txt"), "old-local");
            writeText(fullfile(candidate, "photos", "sentinel.txt"), "candidate-local");
            conflictCleanup = setHook(struct("CandidateRoot", candidate, "Confirm", true));
            testCase.verifyError(@() manageLabKitVersions(root, "install", "Source", selectedSource()), ...
                "LabKit:Deployment:LocalDataConflict");
            testCase.verifyEqual(readMarker(root), "old");
            delete(conflictCleanup)

            failureCleanup = setHook(struct("CandidateRoot", candidate, "Confirm", true, "FailAfterBackup", true));
            testCase.verifyError(@() manageLabKitVersions(root, "install", "Source", selectedSource()), ...
                "LabKit:Deployment:InjectedFailure");
            testCase.verifyEqual(readMarker(root), "old");
            testCase.verifyFalse(any(contains(string(strsplit(path, pathsep)), ".version-backup-")));
            delete(failureCleanup); delete(toolCleanup)
        end

        function browseSelectionAndDoubleClickInstallUseTheSelectedSource(testCase)
            root = fixtureRoot(testCase, "old");
            candidate = fixtureCandidate(testCase, "new");
            [networkFolder, networkCleanup] = networkStubs(testCase);
            toolCleanup = isolatedTool(networkFolder);
            responseCleanup = setAppdata("versionToolWebreadResponses", { ...
                struct("tag_name", {"v1.0.0", "v1.1.0"}, "name", {"First", "Second"}, ...
                    "published_at", {"2026-01-01", "2026-02-01"}, "draft", {false, false}, "prerelease", {false, false}), ...
                struct("name", {}), struct("sha", {})});
            modeCleanup = setAppdata("labkitVersionManagerGuiTestMode", "hidden");
            hookCleanup = setHook(struct("CandidateRoot", candidate, "Confirm", true));

            fig = manageLabKitVersions(root);
            sourceTable = findall(fig, "Type", "uitable");
            invokeTableSelection(sourceTable, 2);
            invokeTableDoubleClick(sourceTable);

            testCase.verifyEqual(readMarker(root), "new");
            testCase.verifyTrue(isappdata(groot, "versionToolWebreadCount"));
            values = textareaValues(fig);
            diagnostic = "row2=" + strjoin(string(sourceTable.Data(2, :)), " | ") + ...
                newline + "text=" + strjoin(values, newline);
            testCase.verifyTrue(any(contains(values, "v1.1.0")), diagnostic);
            expectedRoot = string(root);
            if ispc
                expectedRoot = lower(expectedRoot);
                values = lower(values);
            end
            expectedFolderLine = "Install folder: " + expectedRoot;
            if ispc
                expectedFolderLine = lower(expectedFolderLine);
            end
            testCase.verifyTrue(any(contains(values, expectedFolderLine)));
            delete(fig); delete(hookCleanup); delete(modeCleanup); delete(responseCleanup); delete(toolCleanup); delete(networkCleanup)
        end

        function currentInstallInfoReadsProductionMetadataAndDegradesSafely(testCase)
            root = fixtureRoot(testCase, "old");
            candidate = fixtureCandidate(testCase, "new");
            [networkFolder, networkCleanup] = networkStubs(testCase);
            toolCleanup = isolatedTool(networkFolder);
            responseCleanup = setAppdata("versionToolWebreadResponses", {struct("tag_name", {}) , struct("name", {}), struct("sha", {})});
            modeCleanup = setAppdata("labkitVersionManagerGuiTestMode", "hidden");

            fig = manageLabKitVersions(candidate);
            values = textareaValues(fig);
            testCase.verifyTrue(any(contains(values, "Current launcher: LabKit App Launcher v1.7.0 (2026-07-26)")));
            delete(fig)
            fig = manageLabKitVersions(root);
            values = textareaValues(fig);
            testCase.verifyTrue(any(contains(values, "Current launcher: LabKit App Launcher vunavailable (unavailable)")));
            delete(fig); delete(modeCleanup); delete(responseCleanup); delete(toolCleanup); delete(networkCleanup)
        end

        function discoveryFiltersAndOrdersIndependentSourceGroups(testCase)
            root = fixtureCandidate(testCase, "new");
            [networkFolder, networkCleanup] = networkStubs(testCase);
            toolCleanup = isolatedTool(networkFolder);
            responseCleanup = setAppdata("versionToolWebreadResponses", { ...
                struct("tag_name", {"v2.0.0", "v2.0.0-rc1", "v1.9.0"}, ...
                    "name", {"Release two", "Release candidate", "Draft"}, ...
                    "published_at", {"2026-02-01", "2026-01-31", "2026-01-30"}, ...
                    "draft", {false, false, true}, "prerelease", {false, true, false}), ...
                struct("name", {"v1.8.0", "build-42"}), ...
                struct("sha", {"abcdef123456", "123456789abc"}, ...
                    "commit", {struct("message", "First commit", "author", struct("date", "2026-01-01")), ...
                    struct("message", "Second commit", "author", struct("date", "2025-12-31"))})});
            modeCleanup = setAppdata("labkitVersionManagerGuiTestMode", "hidden");

            fig = manageLabKitVersions(root);
            sourceTable = findall(fig, "Type", "uitable");
            rows = string(sourceTable.Data);

            testCase.verifyEqual(rows(:, 1), ["Release"; "Tag"; "Tag"; "Commit"; "Commit"]);
            testCase.verifyEqual(rows(1, 2), "v2.0.0");
            testCase.verifyFalse(any(contains(rows(:, 2), "rc1")));
            testCase.verifyFalse(any(contains(rows(:, 2), "v1.9.0")));
            delete(fig); delete(modeCleanup); delete(responseCleanup); delete(toolCleanup); delete(networkCleanup)
        end

        function discoveryRetainsOtherGroupsWhenOneEndpointFails(testCase)
            root = fixtureCandidate(testCase, "new");
            [networkFolder, networkCleanup] = networkStubs(testCase);
            toolCleanup = isolatedTool(networkFolder);
            responseCleanup = setAppdata("versionToolWebreadResponses", { ...
                struct("Error", "release endpoint unavailable"), ...
                struct("name", "v1.8.0"), ...
                struct("sha", "abcdef123456", "commit", struct("message", "Commit", "author", struct("date", "2026-01-01")))});
            modeCleanup = setAppdata("labkitVersionManagerGuiTestMode", "hidden");

            fig = manageLabKitVersions(root);
            sourceTable = findall(fig, "Type", "uitable");
            rows = string(sourceTable.Data);

            testCase.verifyEqual(rows(:, 1), ["Tag"; "Commit"]);
            testCase.verifyEqual(rows(1, 2), "v1.8.0");
            delete(fig); delete(modeCleanup); delete(responseCleanup); delete(toolCleanup); delete(networkCleanup)
        end

        function mainAndSelectedModesRequestTheirExactZipUrlsAfterConfirmation(testCase)
            root = fixtureRoot(testCase, "old");
            [networkFolder, networkCleanup] = networkStubs(testCase);
            toolCleanup = isolatedTool(networkFolder);
            hookCleanup = setHook(struct("Confirm", true));

            testCase.verifyError(@() manageLabKitVersions(root, "main"), "fixture:Download");
            mainArguments = getappdata(groot, "versionToolWebsaveArguments");
            testCase.verifyTrue(contains(string(mainArguments{2}), "refs/heads/main.zip"));
            rmappdata(groot, "versionToolWebsaveArguments");
            selected = selectedSource();
            testCase.verifyError(@() manageLabKitVersions(root, "install", "Source", selected), "fixture:Download");
            selectedArguments = getappdata(groot, "versionToolWebsaveArguments");
            testCase.verifyEqual(string(selectedArguments{2}), selected.Url);
            delete(hookCleanup); delete(toolCleanup); delete(networkCleanup)
        end

        function stableModeUsesLatestStableReleaseBeforeTags(testCase)
            root = fixtureRoot(testCase, "old");
            [networkFolder, networkCleanup] = networkStubs(testCase);
            toolCleanup = isolatedTool(networkFolder);
            responseCleanup = setAppdata("versionToolWebreadResponses", { ...
                struct("tag_name", "v2.3.4", "name", "Stable", "draft", false, ...
                    "prerelease", false, "published_at", "2026-01-01")});
            hookCleanup = setHook(struct("Confirm", true));

            testCase.verifyError(@() manageLabKitVersions(root, "stable"), "fixture:Download");

            arguments = getappdata(groot, "versionToolWebsaveArguments");
            testCase.verifyTrue(contains(string(arguments{2}), "refs/tags/v2.3.4.zip"));
            testCase.verifyEqual(getappdata(groot, "versionToolWebreadCount"), 1);
            delete(hookCleanup); delete(responseCleanup); delete(toolCleanup); delete(networkCleanup)
        end

        function stableModeFallsBackOnlyToStrictSemverTags(testCase)
            root = fixtureRoot(testCase, "old");
            [networkFolder, networkCleanup] = networkStubs(testCase);
            toolCleanup = isolatedTool(networkFolder);
            responseCleanup = setAppdata("versionToolWebreadResponses", { ...
                struct(), struct("name", {"v3.0.0-rc1", "build-42", "v2.3.5"})});
            hookCleanup = setHook(struct("Confirm", true));

            testCase.verifyError(@() manageLabKitVersions(root, "stable"), "fixture:Download");

            arguments = getappdata(groot, "versionToolWebsaveArguments");
            testCase.verifyTrue(contains(string(arguments{2}), "refs/tags/v2.3.5.zip"));
            testCase.verifyEqual(getappdata(groot, "versionToolWebreadCount"), 2);
            delete(hookCleanup); delete(responseCleanup); delete(toolCleanup); delete(networkCleanup)
        end

        function stableModeRejectsPagesWithoutAStableTag(testCase)
            root = fixtureRoot(testCase, "old");
            [networkFolder, networkCleanup] = networkStubs(testCase);
            toolCleanup = isolatedTool(networkFolder);
            responseCleanup = setAppdata("versionToolWebreadResponses", { ...
                struct(), struct("name", {"v2.0.0-rc1", "build-42", "v2.3"})});
            hookCleanup = setHook(struct("Confirm", true));

            testCase.verifyError(@() manageLabKitVersions(root, "stable"), ...
                "LabKit:Deployment:StableSourceUnavailable");
            testCase.verifyFalse(isappdata(groot, "versionToolWebsaveCalled"));
            delete(hookCleanup); delete(responseCleanup); delete(toolCleanup); delete(networkCleanup)
        end

    end
end

function cleanup = isolatedTool(networkFolder)
previousPath = path;
root = labkittest.setup();
if strlength(string(networkFolder)) > 0
    addpath(networkFolder, "-begin");
end
addpath(fullfile(root, "tools", "deployment"), "-begin");
clear manageLabKitVersions webread websave
cleanup = onCleanup(@() restoreTool(previousPath));
end

function restoreTool(previousPath)
clear manageLabKitVersions webread websave
path(previousPath);
rehash
end

function root = fixtureRoot(testCase, marker)
container = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
root = fullfile(container, "install-root");
createRoot(root, marker);
end

function createRoot(root, marker)
if exist(root, "dir") ~= 7
    mkdir(root);
end
copyfile(fullfile(labkittest.setup(), "labkit_launcher.m"), root);
mkdir(fullfile(root, "+labkit"));
mkdir(fullfile(root, "apps"));
mkdir(fullfile(root, "tools"));
writeText(fullfile(root, "marker.txt"), marker);
end

function root = fixtureCandidate(testCase, marker)
container = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
root = fullfile(container, "candidate-root");
mkdir(root);
createCandidate(root, marker);
end

function createCandidate(root, marker)
if exist(root, "dir") ~= 7
    mkdir(root);
end
copyfile(fullfile(labkittest.setup(), "labkit_launcher.m"), root);
mkdir(fullfile(root, "+labkit", "+app", "+internal", "+launcher"));
mkdir(fullfile(root, "apps"));
writeText(fullfile(root, "+labkit", "+app", "+internal", "+launcher", "dispatch.m"), strjoin([
    "function dispatch(varargin)"
    "info = struct(""name"", ""labkit_launcher"", ..."
    "    ""displayName"", ""LabKit App Launcher"", ..."
    "    ""version"", ""1.7.0"", ""updated"", ""2026-07-26"");"
    "end"], newline));
writeText(fullfile(root, "marker.txt"), marker);
end

function source = selectedSource()
source = struct( ...
    "Kind", "Tag", ...
    "Label", "Synthetic tag", ...
    "Url", "https://github.com/Pluze/LabKit-MATLAB-Workbench/" + ...
        "archive/refs/tags/v1.2.3.zip", ...
    "Name", "v1.2.3", ...
    "Date", "", ...
    "Summary", "Synthetic source");
end

function cleanup = setHook(value)
key = "labkitVersionManagerTestHook";
hadValue = isappdata(groot, key);
prior = [];
if hadValue
    prior = getappdata(groot, key);
end
setappdata(groot, key, value);
cleanup = onCleanup(@() restoreAppdata(key, hadValue, prior));
end

function [folder, cleanup] = networkStubs(testCase)
folder = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
writeText(fullfile(folder, "webread.m"), strjoin([
    "function value = webread(varargin)"
    "count = 0;"
    "if isappdata(groot, 'versionToolWebreadCount')"
    "    count = getappdata(groot, 'versionToolWebreadCount');"
    "end"
    "setappdata(groot, 'versionToolWebreadCount', count + 1);"
    "if isappdata(groot, 'versionToolWebreadResponses')"
    "    values = getappdata(groot, 'versionToolWebreadResponses');"
    "    if count + 1 <= numel(values)"
    "        value = values{count + 1};"
    "        if isstruct(value) && isscalar(value) && isfield(value, 'Error')"
    "            error('fixture:EndpointFailure', '%s', char(value.Error));"
    "        end"
    "        return"
    "    end"
    "end"
    "error('fixture:Network', 'network should not run');"
    "end"], newline));
writeText(fullfile(folder, "websave.m"), strjoin([
    "function value = websave(varargin)"
    "setappdata(groot, 'versionToolWebsaveCalled', true);"
    "setappdata(groot, 'versionToolWebsaveArguments', varargin);"
    "error('fixture:Download', 'download should not run');"
    "end"], newline));
cleanup = preserveNetworkState();
end

function cleanup = preserveNetworkState()
keys = ["versionToolWebreadCount", "versionToolWebsaveCalled", "versionToolWebreadResponses", "versionToolWebsaveArguments"];
values = cell(size(keys)); had = false(size(keys));
for index = 1:numel(keys)
    had(index) = isappdata(groot, keys(index));
    if had(index)
        values{index} = getappdata(groot, keys(index));
    end
    if isappdata(groot, keys(index))
        rmappdata(groot, keys(index));
    end
end
cleanup = onCleanup(@() restoreNetworkState(keys, had, values));
end

function restoreNetworkState(keys, had, values)
for index = 1:numel(keys)
    if had(index)
        setappdata(groot, keys(index), values{index});
    elseif isappdata(groot, keys(index))
        rmappdata(groot, keys(index));
    end
end
end

function restoreAppdata(key, had, value)
if had
    setappdata(groot, key, value);
elseif isappdata(groot, key)
    rmappdata(groot, key);
end
end

function cleanup = setAppdata(key, value)
had = isappdata(groot, key);
prior = [];
if had
    prior = getappdata(groot, key);
end
setappdata(groot, key, value);
cleanup = onCleanup(@() restoreAppdata(key, had, prior));
end

function writeText(filepath, contents)
folder = fileparts(filepath);
if exist(folder, "dir") ~= 7
    mkdir(folder);
end
file = fopen(filepath, "w", "n", "UTF-8");
cleanup = onCleanup(@() fclose(file));
fprintf(file, "%s", contents);
delete(cleanup)
end

function marker = readMarker(root)
marker = string(strtrim(fileread(fullfile(root, "marker.txt"))));
end

function entries = normalizedPathEntries()
entries = string(strsplit(path, pathsep));
for index = 1:numel(entries)
    if strlength(entries(index)) > 0
        entries(index) = normalizedPath(entries(index));
    end
end
end

function value = normalizedPath(value)
pathValue = java.nio.file.Paths.get(char(value), javaArray("java.lang.String", 0));
value = string(pathValue.toAbsolutePath().normalize().toString());
if ispc
    value = lower(value);
end
end

function values = textareaValues(fig)
textAreas = findall(fig, "Type", "uitextarea");
values = strings(numel(textAreas), 1);
for index = 1:numel(textAreas)
    values(index) = strjoin(string(textAreas(index).Value), newline);
end
end

function invokeTableSelection(sourceTable, row)
if isprop(sourceTable, "SelectionChangedFcn") && ...
        ~isempty(sourceTable.SelectionChangedFcn)
    callback = sourceTable.SelectionChangedFcn;
    callback(sourceTable, struct("Selection", [row 1]));
else
    callback = sourceTable.CellSelectionCallback;
    callback(sourceTable, struct("Indices", [row 1]));
end
end

function invokeTableDoubleClick(sourceTable)
if isprop(sourceTable, "DoubleClickedFcn") && ...
        ~isempty(sourceTable.DoubleClickedFcn)
    callback = sourceTable.DoubleClickedFcn;
else
    callback = sourceTable.CellDoubleClickedFcn;
end
callback(sourceTable, []);
end

function writeAllLocalSentinels(root)
for relative = preservedLocalPaths()'
    if relative == "LabKit.prj"
        writeText(fullfile(root, relative), "synthetic-local");
    else
        writeText(fullfile(root, relative, "sentinel.txt"), "synthetic-local");
    end
end
end

function verifyAllLocalSentinels(testCase, root)
for relative = preservedLocalPaths()'
    if relative == "LabKit.prj"
        filepath = fullfile(root, relative);
    else
        filepath = fullfile(root, relative, "sentinel.txt");
    end
    testCase.verifyEqual(string(strtrim(fileread(filepath))), "synthetic-local");
end
end

function paths = preservedLocalPaths()
paths = [
    "private_apps"
    "artifacts"
    string(fullfile("resources", "project"))
    "photos"
    "derived"
    "profile_results"
    "LabKit.prj"
    ];
end
