classdef LauncherBootstrapSpec < matlab.unittest.TestCase
    % LAUNCHERBOOTSTRAPSPEC Repair-root delegation and recovery affordance contracts.

    methods (Test, TestTags = {'Contract:system', 'Env:headless'})
        function rootOnlyCopyOpensHiddenRepairWithAndWithoutAnOutput(testCase)
            root = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            copyfile(fullfile(labkittest.setup(), "labkit_launcher.m"), root);
            cleanup = isolatedRootLauncher(root);
            stateCleanup = setHiddenRepairMode();

            labkit_launcher;
            repairFigure = findall(groot, "Type", "figure", "Tag", "labkitRepair");
            testCase.verifyNumElements(repairFigure, 1);
            delete(repairFigure);

            repairFigure = labkit_launcher;
            testCase.verifyTrue(isvalid(repairFigure));
            testCase.verifyEqual(string(repairFigure.Tag), "labkitRepair");
            testCase.verifyEqual(string(which("labkit_launcher")), ...
                string(fullfile(root, "labkit_launcher.m")));
            delete(repairFigure);
            delete(stateCleanup); delete(cleanup)
        end

        function missingInstalledEntryRejectsOutputModes(testCase)
            root = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            copyfile(fullfile(labkittest.setup(), "labkit_launcher.m"), root);
            cleanup = isolatedRootLauncher(root);

            testCase.verifyError(@() labkit_launcher("list"), ...
                "labkit_launcher:InstalledEntryUnavailable");
            testCase.verifyError(@() labkit_launcher("version"), ...
                "labkit_launcher:InstalledEntryUnavailable");
            testCase.verifyError(@() labkit_launcher("documentation", "labkit_Probe_app"), ...
                "labkit_launcher:InstalledEntryUnavailable");
            delete(cleanup)
        end

        function healthyRootDelegatesThroughTheInstalledEntry(testCase)
            [~, cleanup] = installedLauncherFixture(testCase);
            stateCleanup = preserveAppdata("labkitLauncherDelegateFixture");
            setappdata(groot, "labkitLauncherDelegateFixture", struct());

            listing = labkit_launcher("list");

            testCase.verifyEqual(string(listing.Command), "labkit_Probe_app");
            delete(stateCleanup); delete(cleanup)
        end

        function structuralStartupFailureOpensRepairAndPreservesItsCause(testCase)
            [~, cleanup] = installedLauncherFixture(testCase);
            stateCleanup = setDelegateFailure("MATLAB:UndefinedFunction", "fixture dispatch symbol is unavailable");

            repairFigure = labkit_launcher;
            text = string(findall(repairFigure, "Type", "uitextarea").Value);

            testCase.verifyTrue(any(contains(text, "MATLAB:UndefinedFunction")));
            testCase.verifyTrue(any(contains(text, "fixture dispatch symbol is unavailable")));
            testCase.verifyTrue(any(contains(text, "Repair / Reinstall")));
            delete(repairFigure); delete(stateCleanup); delete(cleanup)
        end

        function missingInstalledClassStartupFailureOpensRepair(testCase)
            [~, cleanup] = installedLauncherFixture(testCase);
            stateCleanup = setDelegateFailure("MATLAB:undefinedVarOrClass", "fixture installed class is unavailable");

            repairFigure = labkit_launcher;
            text = string(findall(repairFigure, "Type", "uitextarea").Value);

            testCase.verifyTrue(any(contains(text, "MATLAB:undefinedVarOrClass")));
            testCase.verifyTrue(any(contains(text, "Repair / Reinstall")));
            delete(repairFigure); delete(stateCleanup); delete(cleanup)
        end

        function ordinaryStartupFailuresDoNotBecomeRepairFailures(testCase)
            [~, cleanup] = installedLauncherFixture(testCase);
            stateCleanup = setDelegateFailure("MATLAB:load:couldNotReadFile", "fixture input cannot be read");

            testCase.verifyError(@() labkit_launcher, "MATLAB:load:couldNotReadFile");
            testCase.verifyEmpty(findall(groot, "Type", "figure", "Tag", "labkitRepair"));
            delete(stateCleanup);
            stateCleanup = setDelegateFailure("fixture:InvalidInput", "fixture input is invalid");
            testCase.verifyError(@() labkit_launcher, "fixture:InvalidInput");
            testCase.verifyEmpty(findall(groot, "Type", "figure", "Tag", "labkitRepair"));
            delete(stateCleanup); delete(cleanup)
        end

        function structuralOutputModePreservesTheOriginalFailure(testCase)
            [~, cleanup] = installedLauncherFixture(testCase);
            stateCleanup = setDelegateFailure("MATLAB:UndefinedFunction", "fixture dispatch symbol is unavailable");

            testCase.verifyError(@() labkit_launcher("list"), "MATLAB:UndefinedFunction");
            testCase.verifyEmpty(findall(groot, "Type", "figure", "Tag", "labkitRepair"));
            delete(stateCleanup); delete(cleanup)
        end

        function fixtureLauncherIgnoresAnEarlierShadowDispatchPackage(testCase)
            [root, cleanup] = installedLauncherFixture(testCase);
            shadow = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            writeText(fullfile(shadow, "+labkit", "+app", "+internal", "+launcher", "dispatch.m"), ...
                dispatcherStub("labkit_Shadow_app"));
            fixtureLauncher = @labkit_launcher;
            testCase.verifyEqual(string(functions(fixtureLauncher).file), ...
                string(fullfile(root, "labkit_launcher.m")));
            addpath(shadow, "-begin");
            rehash;
            clear labkit.app.internal.launcher.dispatch

            listing = fixtureLauncher("list");

            testCase.verifyEqual(string(listing.Command), "labkit_Probe_app");
            delete(cleanup)
        end

        function repairRootDoesNotContainRuntimeLoggingOrStaticDispatchCalls(testCase)
            source = string(fileread(fullfile(labkittest.setup(), "labkit_launcher.m")));

            testCase.verifyFalse(contains(source, "SessionEvent", "IgnoreCase", true));
            testCase.verifyFalse(contains(source, "SessionJournal", "IgnoreCase", true));
            testCase.verifyFalse(contains(source, "journal", "IgnoreCase", true));
            testCase.verifyFalse(contains(source, "bootstrap logging", "IgnoreCase", true));
            testCase.verifyFalse(contains(source, "Version Manager", "IgnoreCase", true));
            testCase.verifyFalse(contains(source, ".labkit-managed-files.txt", "IgnoreCase", true));
            testCase.verifyTrue(contains(source, ...
                'str2func("labkit.app.internal.launcher.dispatch")'));
            testCase.verifyFalse(contains(source, "labkit.app.internal.launcher.dispatch("));
            testCase.verifyTrue(contains(source, ...
                'strlength(string(folder)) > 0 && exist(folder, "dir") == 7'));
            testCase.verifyTrue(contains(source, ...
                'repairFailureMessage(cause), detail, backup'));
        end

        function repairUiRejectsAnInvalidCandidateWithoutChangingTheTarget(testCase)
            root = damagedRepairRoot(testCase, "old-marker", false);
            candidate = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            [repairFigure, cleanup] = openRepairFixture(root);
            hookCleanup = setRepairHook(struct("CandidateRoot", candidate));

            clickRepair(repairFigure);
            status = repairStatus(repairFigure);

            testCase.verifyTrue(contains(status, "labkit_launcher:InvalidCandidate"));
            testCase.verifyEqual(readMarker(root), "old-marker");
            delete(hookCleanup); delete(cleanup)
        end

        function repairUiRejectsACandidateContainedByTheTarget(testCase)
            root = damagedRepairRoot(testCase, "old-marker", false);
            candidate = fullfile(root, "candidate");
            createValidCandidate(candidate, "candidate-marker", false);
            [repairFigure, cleanup] = openRepairFixture(root);
            hookCleanup = setRepairHook(struct("CandidateRoot", candidate));

            clickRepair(repairFigure);

            testCase.verifyTrue(contains(repairStatus(repairFigure), ...
                "labkit_launcher:InvalidCandidate"));
            testCase.verifyEqual(readMarker(root), "old-marker");
            delete(hookCleanup); delete(cleanup)
        end

        function repairUiRejectsATargetContainedByTheCandidate(testCase)
            candidate = validRepairCandidate(testCase, "candidate-marker", false);
            root = fullfile(candidate, "nested-install");
            createDamagedRepairRoot(root, "old-marker", false);
            [repairFigure, cleanup] = openRepairFixture(root);
            hookCleanup = setRepairHook(struct("CandidateRoot", candidate));

            clickRepair(repairFigure);

            testCase.verifyTrue(contains(repairStatus(repairFigure), ...
                "labkit_launcher:InvalidCandidate"));
            testCase.verifyEqual(readMarker(root), "old-marker");
            delete(hookCleanup); delete(cleanup)
        end

        function rootOnlyCopyRepairIsSafelyRejected(testCase)
            root = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            copyfile(fullfile(labkittest.setup(), "labkit_launcher.m"), root);
            [repairFigure, cleanup] = openRepairFixture(root);

            clickRepair(repairFigure);

            testCase.verifyTrue(contains(repairStatus(repairFigure), ...
                "labkit_launcher:InvalidRepairRoot"));
            testCase.verifyEqual(exist(fullfile(root, "labkit_launcher.m"), "file"), 2);
            delete(cleanup)
        end

        function repairUiReplacesAValidDamagedInstallationAndRestoresWorkingFolder(testCase)
            root = damagedRepairRoot(testCase, "old-marker", true);
            candidate = validRepairCandidate(testCase, "new-marker", true);
            mkdir(fullfile(root, "apps", "probe"));
            mkdir(fullfile(root, "tools", "local-only"));
            mkdir(fullfile(candidate, "apps", "probe"));
            [repairFigure, cleanup] = openRepairFixture(root);
            hookCleanup = setRepairHook(struct("CandidateRoot", candidate));
            addpath(fullfile(root, "apps", "probe"), "-begin");
            addpath(fullfile(root, "tools", "local-only"), "-begin");
            originalFolder = pwd;
            folderCleanup = onCleanup(@() cd(originalFolder));
            cd(fullfile(root, "session"));

            clickRepair(repairFigure);

            testCase.verifyTrue(contains(repairStatus(repairFigure), "Restart LabKit"));
            testCase.verifyEqual(readMarker(root), "new-marker");
            testCase.verifyEqual(normalizedPath(pwd), normalizedPath(fullfile(root, "session")));
            testCase.verifyEqual(exist(fullfile(root, "+labkit", "+app", "+internal", "+launcher", "dispatch.m"), "file"), 2);
            testCase.verifyEmpty(dir(fullfile(fileparts(root), "*.repair-backup-*")));
            entries = normalizedPathEntries();
            testCase.verifyTrue(any(entries == normalizedPath(root)));
            testCase.verifyTrue(any(entries == normalizedPath(fullfile(root, "apps", "probe"))));
            testCase.verifyFalse(any(entries == normalizedPath(fullfile(root, "tools", "local-only"))));
            testCase.verifyFalse(any(contains(entries, ".repair-backup-")));
            delete(folderCleanup); delete(hookCleanup); delete(cleanup)
        end

        function repairMigratesLocalDataAndRetainsARecoveryBackup(testCase)
            root = damagedRepairRoot(testCase, "old-marker", false);
            candidate = validRepairCandidate(testCase, "new-marker", false);
            writePreservedLocalSentinels(root);
            writeText(fullfile(root, ".labkit-managed-files.txt"), "obsolete-ledger");
            [repairFigure, cleanup] = openRepairFixture(root);
            hookCleanup = setRepairHook(struct("CandidateRoot", candidate));

            clickRepair(repairFigure);

            verifyPreservedLocalSentinels(testCase, root);
            testCase.verifyEqual(exist(fullfile(root, ".labkit-managed-files.txt"), "file"), 0);
            backups = dir(fullfile(fileparts(root), "*.repair-backup-*"));
            testCase.verifyNumElements(backups, 1);
            backup = fullfile(backups(1).folder, backups(1).name);
            verifyPreservedLocalSentinels(testCase, backup);
            testCase.verifyEqual(readMarker(backup), "old-marker");
            status = repairStatus(repairFigure);
            testCase.verifyTrue(contains(status, "Recovery backup retained at"));
            testCase.verifyTrue(contains(status, string(backup)));
            delete(hookCleanup); delete(cleanup)
        end

        function candidateLocalDataConflictRollsBackTheCompleteInstallation(testCase)
            root = damagedRepairRoot(testCase, "old-marker", false);
            candidate = validRepairCandidate(testCase, "new-marker", false);
            writeText(fullfile(root, "photos", "sentinel.txt"), "old-local-data");
            writeText(fullfile(candidate, "photos", "sentinel.txt"), "candidate-content");
            writeText(fullfile(candidate, "candidate-only.txt"), "candidate-only");
            [repairFigure, cleanup] = openRepairFixture(root);
            hookCleanup = setRepairHook(struct("CandidateRoot", candidate));

            clickRepair(repairFigure);

            testCase.verifyTrue(contains(repairStatus(repairFigure), ...
                "labkit_launcher:LocalDataConflict"));
            testCase.verifyEqual(readMarker(root), "old-marker");
            testCase.verifyEqual(string(strtrim(fileread( ...
                fullfile(root, "photos", "sentinel.txt")))), "old-local-data");
            testCase.verifyEqual(exist(fullfile(root, "candidate-only.txt"), "file"), 0);
            testCase.verifyEqual(string(strtrim(fileread( ...
                fullfile(candidate, "photos", "sentinel.txt")))), "candidate-content");
            testCase.verifyEmpty(dir(fullfile(fileparts(root), "*.repair-backup-*")));
            delete(hookCleanup); delete(cleanup)
        end

        function injectedFailureAfterBackupRestoresTheOriginalInstallation(testCase)
            root = damagedRepairRoot(testCase, "old-marker", false);
            candidate = validRepairCandidate(testCase, "new-marker", false);
            mkdir(fullfile(root, "tools", "rollback-path"));
            [repairFigure, cleanup] = openRepairFixture(root);
            hookCleanup = setRepairHook(struct("CandidateRoot", candidate, "FailAfterBackup", true));
            addpath(fullfile(root, "tools", "rollback-path"), "-begin");
            startingFolder = pwd;

            clickRepair(repairFigure);

            testCase.verifyTrue(contains(repairStatus(repairFigure), "labkit_launcher:InjectedFailure"));
            testCase.verifyEqual(readMarker(root), "old-marker");
            testCase.verifyEqual(readMarker(candidate), "new-marker");
            testCase.verifyEqual(normalizedPath(pwd), normalizedPath(startingFolder));
            testCase.verifyEmpty(dir(fullfile(fileparts(root), "*.repair-backup-*")));
            entries = normalizedPathEntries();
            testCase.verifyTrue(any(entries == normalizedPath(root)));
            testCase.verifyTrue(any(entries == normalizedPath(fullfile(root, "tools", "rollback-path"))));
            testCase.verifyFalse(any(contains(entries, ".repair-backup-")));
            delete(hookCleanup); delete(cleanup)
        end

        function gitCheckoutRepairRejectsBeforeAnyNetworkRequest(testCase)
            root = damagedRepairRoot(testCase, "old-marker", false);
            mkdir(fullfile(root, ".git"));
            networkFolder = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            writeNetworkStubs(networkFolder);
            [repairFigure, cleanup] = openRepairFixture(root);
            networkCleanup = isolatedNetworkStubs(networkFolder);

            clickRepair(repairFigure);

            testCase.verifyTrue(contains(repairStatus(repairFigure), "labkit_launcher:GitCheckout"));
            testCase.verifyFalse(isappdata(groot, "fixtureWebreadCount"));
            delete(networkCleanup); delete(cleanup)
        end

        function linkedWorktreeRepairRejectsBeforeAnyNetworkRequest(testCase)
            root = damagedRepairRoot(testCase, "old-marker", false);
            writeText(fullfile(root, ".git"), "gitdir: synthetic-worktree");
            networkFolder = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            writeNetworkStubs(networkFolder);
            [repairFigure, cleanup] = openRepairFixture(root);
            networkCleanup = isolatedNetworkStubs(networkFolder);

            clickRepair(repairFigure);

            testCase.verifyTrue(contains(repairStatus(repairFigure), "labkit_launcher:GitCheckout"));
            testCase.verifyFalse(isappdata(groot, "fixtureWebreadCount"));
            testCase.verifyFalse(isappdata(groot, "fixtureWebsaveCalled"));
            delete(networkCleanup); delete(cleanup)
        end

        function stableTagFallbackSkipsPrereleasesAndUsesTheFirstStableTag(testCase)
            root = damagedRepairRoot(testCase, "old-marker", false);
            networkFolder = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            writeNetworkStubs(networkFolder);
            [repairFigure, cleanup] = openRepairFixture(root);
            networkCleanup = isolatedNetworkStubs(networkFolder);
            sequenceCleanup = setWebreadSequence({struct(), struct("name", ...
                {"v2.0.0-rc1", "v1.4.2", "preview"})});

            clickRepair(repairFigure);

            testCase.verifyEqual(getappdata(groot, "fixtureWebreadCount"), 2);
            testCase.verifyTrue(isappdata(groot, "fixtureWebsaveCalled"));
            arguments = getappdata(groot, "fixtureWebsaveArguments");
            testCase.verifyTrue(contains(string(arguments{2}), "refs/tags/v1.4.2.zip"));
            testCase.verifyTrue(contains(repairStatus(repairFigure), "fixture:UnexpectedDownload"));
            delete(sequenceCleanup); delete(networkCleanup); delete(cleanup)
        end

        function stableTagFallbackRejectsPagesWithoutASemverRelease(testCase)
            root = damagedRepairRoot(testCase, "old-marker", false);
            networkFolder = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            writeNetworkStubs(networkFolder);
            [repairFigure, cleanup] = openRepairFixture(root);
            networkCleanup = isolatedNetworkStubs(networkFolder);
            sequenceCleanup = setWebreadSequence({struct(), struct("name", ...
                {"v2.0.0-rc1", "release-candidate", "v1.2"})});

            clickRepair(repairFigure);

            testCase.verifyTrue(contains(repairStatus(repairFigure), ...
                "labkit_launcher:StableSourceUnavailable"));
            testCase.verifyEqual(getappdata(groot, "fixtureWebreadCount"), 2);
            testCase.verifyFalse(isappdata(groot, "fixtureWebsaveCalled"));
            delete(sequenceCleanup); delete(networkCleanup); delete(cleanup)
        end

        function networkFailureIsActionableAndDoesNotAttemptDownload(testCase)
            root = damagedRepairRoot(testCase, "old-marker", false);
            networkFolder = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            writeNetworkStubs(networkFolder);
            [repairFigure, cleanup] = openRepairFixture(root);
            networkCleanup = isolatedNetworkStubs(networkFolder);

            clickRepair(repairFigure);

            testCase.verifyTrue(contains(repairStatus(repairFigure), ...
                "labkit_launcher:StableSourceUnavailable"));
            testCase.verifyEqual(getappdata(groot, "fixtureWebreadCount"), 2);
            testCase.verifyFalse(isappdata(groot, "fixtureWebsaveCalled"));
            delete(networkCleanup); delete(cleanup)
        end
    end
end

function cleanup = isolatedRootLauncher(root)
previousPath = path;
addpath(root, "-begin");
clear labkit_launcher
cleanup = onCleanup(@() restoreRootLauncher(previousPath));
end

function restoreRootLauncher(previousPath)
close(findall(groot, "Type", "figure", "Tag", "labkitRepair"));
clear labkit_launcher labkit.app.internal.launcher.dispatch
path(previousPath);
rehash
end

function [root, cleanup] = installedLauncherFixture(testCase)
root = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
copyfile(fullfile(labkittest.setup(), "labkit_launcher.m"), root);
writeText(fullfile(root, "+labkit", "+app", "+internal", "+launcher", "dispatch.m"), ...
    dispatcherStub("labkit_Probe_app"));
cleanup = isolatedRootLauncher(root);
end

function cleanup = setHiddenRepairMode()
cleanup = preserveAppdata("labkitLauncherGuiTestMode");
setappdata(groot, "labkitLauncherGuiTestMode", "hidden");
end

function cleanup = setDelegateFailure(identifier, message)
cleanup = preserveAppdata("labkitLauncherDelegateFixture");
setappdata(groot, "labkitLauncherDelegateFixture", ...
    struct("Identifier", string(identifier), "Message", string(message)));
end

function cleanup = preserveAppdata(key)
hadValue = isappdata(groot, key);
priorValue = [];
if hadValue
    priorValue = getappdata(groot, key);
end
cleanup = onCleanup(@() restoreAppdata(key, hadValue, priorValue));
end

function restoreAppdata(key, hadValue, priorValue)
if hadValue
    setappdata(groot, key, priorValue);
elseif isappdata(groot, key)
    rmappdata(groot, key);
end
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

function contents = dispatcherStub(command)
contents = strjoin([
    "function varargout = dispatch(~, varargin)"
    "control = struct();"
    "if isappdata(groot, 'labkitLauncherDelegateFixture'), control = getappdata(groot, 'labkitLauncherDelegateFixture'); end"
    "if isfield(control, 'Identifier') && strlength(string(control.Identifier)) > 0"
    "    error(char(control.Identifier), '%s', char(control.Message));"
    "end"
    "result = table(string('" + string(command) + "'), 'VariableNames', {'Command'});"
    "if nargout > 0, varargout{1} = result; end"
    "end"], newline);
end

function root = damagedRepairRoot(testCase, marker, includeSessionFolder)
container = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
root = fullfile(container, "repair-root");
mkdir(root);
createDamagedRepairRoot(root, marker, includeSessionFolder);
end

function createDamagedRepairRoot(root, marker, includeSessionFolder)
if exist(root, "dir") ~= 7
    mkdir(root);
end
copyfile(fullfile(labkittest.setup(), "labkit_launcher.m"), root);
mkdir(fullfile(root, "+labkit"));
mkdir(fullfile(root, "apps"));
mkdir(fullfile(root, "tools"));
writeText(fullfile(root, "install-marker.txt"), marker);
if includeSessionFolder
    mkdir(fullfile(root, "session"));
end
end

function root = validRepairCandidate(testCase, marker, includeSessionFolder)
container = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
root = fullfile(container, "candidate-root");
mkdir(root);
createValidCandidate(root, marker, includeSessionFolder);
end

function createValidCandidate(root, marker, includeSessionFolder)
if exist(root, "dir") ~= 7
    mkdir(root);
end
copyfile(fullfile(labkittest.setup(), "labkit_launcher.m"), root);
mkdir(fullfile(root, "+labkit"));
mkdir(fullfile(root, "apps"));
writeText(fullfile(root, "+labkit", "+app", "+internal", "+launcher", "dispatch.m"), ...
    dispatcherStub("labkit_Candidate_app"));
writeText(fullfile(root, "install-marker.txt"), marker);
if includeSessionFolder
    mkdir(fullfile(root, "session"));
end
end

function [repairFigure, cleanup] = openRepairFixture(root)
pathCleanup = isolatedRootLauncher(root);
modeCleanup = setHiddenRepairMode();
repairFigure = labkit_launcher;
cleanup = onCleanup(@() restoreRepairFixture(repairFigure, modeCleanup, pathCleanup));
end

function restoreRepairFixture(repairFigure, modeCleanup, pathCleanup)
if isvalid(repairFigure)
    delete(repairFigure);
end
delete(modeCleanup);
delete(pathCleanup);
end

function cleanup = setRepairHook(value)
cleanup = preserveAppdata("labkitLauncherRepairTestHook");
setappdata(groot, "labkitLauncherRepairTestHook", value);
end

function clickRepair(repairFigure)
button = findall(repairFigure, "Type", "uibutton", ...
    "Text", "Repair / Reinstall Latest Stable Release");
button.ButtonPushedFcn(button, []);
end

function text = repairStatus(repairFigure)
label = findall(repairFigure, "Type", "uilabel");
text = string(label.Text);
end

function value = readMarker(root)
value = string(strtrim(fileread(fullfile(root, "install-marker.txt"))));
end

function writeNetworkStubs(folder)
writeText(fullfile(folder, "webread.m"), strjoin([
    "function value = webread(varargin)"
    "count = 0; if isappdata(groot, 'fixtureWebreadCount'), count = getappdata(groot, 'fixtureWebreadCount'); end"
    "setappdata(groot, 'fixtureWebreadCount', count + 1);"
    "if isappdata(groot, 'fixtureWebreadResponseSequence')"
    "    sequence = getappdata(groot, 'fixtureWebreadResponseSequence');"
    "    if count + 1 <= numel(sequence), value = sequence{count + 1}; return; end"
    "end"
    "error('fixture:NoNetwork', 'network unavailable');"
    "end"], newline));
writeText(fullfile(folder, "websave.m"), strjoin([
    "function value = websave(varargin)"
    "setappdata(groot, 'fixtureWebsaveCalled', true);"
    "setappdata(groot, 'fixtureWebsaveArguments', varargin);"
    "error('fixture:UnexpectedDownload', 'download should not occur');"
    "end"], newline));
end

function cleanup = setWebreadSequence(sequence)
cleanup = preserveAppdata("fixtureWebreadResponseSequence");
setappdata(groot, "fixtureWebreadResponseSequence", sequence);
end

function cleanup = isolatedNetworkStubs(folder)
previousPath = path;
hadReadCount = isappdata(groot, "fixtureWebreadCount"); readCount = [];
hadWebsave = isappdata(groot, "fixtureWebsaveCalled"); websaveValue = [];
hadWebsaveArguments = isappdata(groot, "fixtureWebsaveArguments"); websaveArguments = [];
hadSequence = isappdata(groot, "fixtureWebreadResponseSequence"); sequence = [];
if hadReadCount, readCount = getappdata(groot, "fixtureWebreadCount"); end
if hadWebsave, websaveValue = getappdata(groot, "fixtureWebsaveCalled"); end
if hadWebsaveArguments, websaveArguments = getappdata(groot, "fixtureWebsaveArguments"); end
if hadSequence, sequence = getappdata(groot, "fixtureWebreadResponseSequence"); end
if isappdata(groot, "fixtureWebreadCount"), rmappdata(groot, "fixtureWebreadCount"); end
if isappdata(groot, "fixtureWebsaveCalled"), rmappdata(groot, "fixtureWebsaveCalled"); end
if isappdata(groot, "fixtureWebsaveArguments"), rmappdata(groot, "fixtureWebsaveArguments"); end
if isappdata(groot, "fixtureWebreadResponseSequence"), rmappdata(groot, "fixtureWebreadResponseSequence"); end
addpath(folder, "-begin");
clear webread websave
cleanup = onCleanup(@() restoreNetworkStubs(previousPath, hadReadCount, readCount, hadWebsave, websaveValue, ...
    hadWebsaveArguments, websaveArguments, hadSequence, sequence));
end

function restoreNetworkStubs(previousPath, hadReadCount, readCount, hadWebsave, websaveValue, ...
        hadWebsaveArguments, websaveArguments, hadSequence, sequence)
clear webread websave
path(previousPath);
if hadReadCount, setappdata(groot, "fixtureWebreadCount", readCount); elseif isappdata(groot, "fixtureWebreadCount"), rmappdata(groot, "fixtureWebreadCount"); end
if hadWebsave, setappdata(groot, "fixtureWebsaveCalled", websaveValue); elseif isappdata(groot, "fixtureWebsaveCalled"), rmappdata(groot, "fixtureWebsaveCalled"); end
if hadWebsaveArguments, setappdata(groot, "fixtureWebsaveArguments", websaveArguments); elseif isappdata(groot, "fixtureWebsaveArguments"), rmappdata(groot, "fixtureWebsaveArguments"); end
if hadSequence, setappdata(groot, "fixtureWebreadResponseSequence", sequence); elseif isappdata(groot, "fixtureWebreadResponseSequence"), rmappdata(groot, "fixtureWebreadResponseSequence"); end
end

function value = normalizedPath(value)
pathValue = java.nio.file.Paths.get(char(value), javaArray("java.lang.String", 0));
value = string(pathValue.toAbsolutePath().normalize().toString());
if ispc
    value = lower(value);
end
end

function entries = normalizedPathEntries()
entries = string(strsplit(path, pathsep));
for index = 1:numel(entries)
    if strlength(entries(index)) > 0
        entries(index) = normalizedPath(entries(index));
    end
end
end

function writePreservedLocalSentinels(root)
directories = [
    "private_apps"
    "artifacts"
    string(fullfile("resources", "project"))
    "photos"
    "derived"
    "profile_results"
    ];
for index = 1:numel(directories)
    writeText(fullfile(root, directories(index), "sentinel.txt"), ...
        "synthetic-preserved");
end
writeText(fullfile(root, "LabKit.prj"), "synthetic-project");
end

function verifyPreservedLocalSentinels(testCase, root)
directories = [
    "private_apps"
    "artifacts"
    string(fullfile("resources", "project"))
    "photos"
    "derived"
    "profile_results"
    ];
for index = 1:numel(directories)
    testCase.verifyEqual(string(strtrim(fileread( ...
        fullfile(root, directories(index), "sentinel.txt")))), ...
        "synthetic-preserved");
end
testCase.verifyEqual(string(strtrim(fileread(fullfile(root, "LabKit.prj")))), ...
    "synthetic-project");
end
