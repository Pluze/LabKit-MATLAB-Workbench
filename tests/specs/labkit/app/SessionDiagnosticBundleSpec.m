classdef SessionDiagnosticBundleSpec < matlab.unittest.TestCase
    % SESSIONDIAGNOSTICBUNDLESPEC Specify complete compact bundles.

    properties (Access = private)
        DiagnosticFilesBefore (1, :) string = strings(1, 0)
    end

    methods (TestMethodSetup)
        function rememberDiagnosticArtifacts(testCase)
            testCase.DiagnosticFilesBefore = diagnosticFiles( ...
                diagnosticArtifactsFolder()).';
        end
    end

    methods (TestMethodTeardown)
        function removeGeneratedDiagnosticArtifacts(testCase)
            folder = diagnosticArtifactsFolder();
            created = setdiff( ...
                diagnosticFiles(folder), ...
                testCase.DiagnosticFilesBefore);
            deleteDiagnostics(folder, created);
        end
    end

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function exportsCompleteEventsAndCompactState(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            definition = bundleDefinition();
            runtime = labkit.app.internal.runtime.RuntimeFactory.createHeadless( ...
                definition, [], struct(), ...
                [], ...
                JournalRoot=folder);
            cleanup = onCleanup(@() runtime.close());
            runtime.invokeAction("run");

            destination = runtime.exportDiagnosticBundle( ...
                fullfile(folder, "diagnostics"));
            unpacked = fullfile(folder, "unpacked");
            unzip(destination, unpacked);
            files = dir(unpacked);
            files = sort(string({files(~[files.isdir]).name}));
            expected = sort([
                "README.txt"
                "manifest.json"
                "events.jsonl"
                "session.log.txt"
                "errors.json"
                "bundle-report.json"
                "app-state-compact.mat"
                ]);

            testCase.verifyTrue(endsWith(destination, ".zip"));
            testCase.verifyEqual(files(:), expected);
            events = readEvents(unpacked);
            testCase.verifyGreaterThan(numel(events), 1);
            testCase.verifyGreaterThan( ...
                min(diff(double([events.sequence]))), 0);
            names = string({events.eventName});
            testCase.verifyTrue(any(names == "analysis.completed"));
            testCase.verifyTrue(any(names == "analysis.failed"));
            testCase.verifyFalse(any( ...
                names == "diagnostics.bundle_exported.started"));
            errors = jsondecode(fileread( ...
                fullfile(unpacked, "errors.json")));
            testCase.verifyEqual( ...
                string(errors.exception.identifier), ...
                "labkit:test:SyntheticIncident");
            report = jsondecode(fileread( ...
                fullfile(unpacked, "bundle-report.json")));
            testCase.verifyEqual( ...
                string(report.eventProjection), ...
                "complete-retained-events");
            testCase.verifyTrue(report.containsSensitiveDetails);
            testCase.verifyEqual(string(report.stateReview.mode), "compact");
            testCase.verifyEqual(report.stateReview.replacementCount, 0);
            saved = load(fullfile(unpacked, "app-state-compact.mat"));
            testCase.verifyTrue(isstruct(saved.applicationState));
            testCase.verifyTrue(isscalar(saved.applicationState));

            bundleText = join(readAllBundleText( ...
                unpacked, ["README.txt"; "events.jsonl"; ...
                "session.log.txt"; "errors.json"]), newline);
            testCase.verifyTrue(contains(bundleText, ...
                "/synthetic/private-source.png"));
            clear cleanup
        end

        function fallsBackToCompleteMemoryWhenTheJournalIsUnavailable(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            definition = bundleDefinition();
            journal = labkit.app.internal.diagnostics.SessionJournal( ...
                definition, RootFolder=folder, ...
                SessionId="session-bundle-fallback", ...
                FaultInjector=@failJournalInitialize);
            runtime = labkit.app.internal.runtime.RuntimeFactory.createHeadless( ...
                definition, [], struct(), ...
                journal);
            cleanup = onCleanup(@() runtime.close());
            runtime.invokeAction("run");

            destination = runtime.exportDiagnosticBundle( ...
                fullfile(folder, "fallback.zip"));
            unpacked = fullfile(folder, "fallback");
            unzip(destination, unpacked);
            events = readEvents(unpacked);
            names = string({events.eventName});

            testCase.verifyTrue(any(names == "analysis.completed"));
            testCase.verifyTrue(any(names == "journal.degraded"));
            readme = string(fileread( ...
                fullfile(unpacked, "README.txt")));
            testCase.verifyTrue(contains( ...
                readme, "Journal dropped records:"));
            clear cleanup
        end

        function compactStateReplacesOnlyLargeSupportedLeaves(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            definition = bundleDefinition();
            runtime = labkit.app.internal.runtime.RuntimeFactory.createHeadless( ...
                definition, [], struct(), [], JournalRoot=folder);
            cleanup = onCleanup(@() runtime.close());
            runtime.invokeAction("largeState");

            expectedCache = runtime.State.session.cache;
            compact = runtime.exportDiagnosticBundle( ...
                fullfile(folder, "compact.zip"));
            compactFolder = fullfile(folder, "compact");
            unzip(compact, compactFolder);
            compactState = load( ...
                fullfile(compactFolder, "app-state-compact.mat"));
            compactCache = compactState.applicationState.session.cache;

            testCase.verifyEqual(class(compactCache.largePayload), ...
                class(expectedCache.largePayload));
            testCase.verifyEqual(size(compactCache.largePayload), ...
                size(expectedCache.largePayload));
            testCase.verifyNotEqual(compactCache.largePayload, ...
                expectedCache.largePayload);
            testCase.verifyEqual(compactCache.largePayload, ...
                zeros(size(expectedCache.largePayload), "uint8"));
            testCase.verifyEqual(compactCache.smallDiagnosticValues, ...
                expectedCache.smallDiagnosticValues);

            report = jsondecode(fileread( ...
                fullfile(compactFolder, "bundle-report.json")));
            testCase.verifyEqual(string(report.stateReview.mode), "compact");
            testCase.verifyEqual(report.stateReview.replacementCount, 1);
            testCase.verifyEqual( ...
                report.stateReview.retainedLargeValueCount, 0);
            testCase.verifyTrue(endsWith( ...
                string(report.stateReview.replacements.statePath), ...
                ".largePayload"));
            testCase.verifyGreaterThan( ...
                report.stateReview.replacements.originalBytes, 1024 ^ 2);
            clear cleanup
        end

        function writesOneReadableTextFallbackBesideTheAutomaticZip(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            definition = bundleDefinition();
            runtime = labkit.app.internal.runtime.RuntimeFactory.createHeadless( ...
                definition, [], struct(), [], JournalRoot=folder);
            cleanup = onCleanup(@() runtime.close());
            runtime.invokeAction("run");

            destination = runtime.exportDiagnosticTextFallback( ...
                fullfile(folder, "diagnostics.zip"), ...
                MException( ...
                    "labkit:app:runtime:DiagnosticWriteFailed", ...
                    "Synthetic ZIP failure."));
            fileCleanup = onCleanup(@() deleteIfFile(destination));
            fallback = string(fileread(destination));

            testCase.verifyTrue(endsWith(destination, ".txt"));
            testCase.verifyTrue(isfile(destination));
            testCase.verifyTrue(contains( ...
                fallback, "LabKit Diagnostic Text Fallback"));
            testCase.verifyTrue(contains( ...
                fallback, "analysis.failed"));
            testCase.verifyTrue(contains( ...
                fallback, "diagnostics.text_fallback.started"));
            testCase.verifyTrue(contains(fallback, ...
                "labkit:app:runtime:DiagnosticWriteFailed"));
            testCase.verifyTrue(contains( ...
                fallback, "private-source.png"));
            testCase.verifyTrue(contains(fallback, ...
                "app-state-compact.mat could not be represented"));
            clear fileCleanup cleanup
        end

        function textFallbackNamesTheMissingCompactState(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            runtime = labkit.app.internal.runtime.RuntimeFactory.createHeadless( ...
                bundleDefinition(), [], struct(), [], JournalRoot=folder);
            cleanup = onCleanup(@() runtime.close());
            runtime.invokeAction("run");

            destination = runtime.exportDiagnosticTextFallback( ...
                fullfile(folder, "diagnostics-sensitive.zip"), ...
                MException("labkit:test:ZipFailure", ...
                    "Synthetic ZIP failure."));
            fallback = string(fileread(destination));

            testCase.verifyTrue(contains(fallback, ...
                "preserves complete sensitive event details"));
            testCase.verifyTrue(contains(fallback, ...
                "/synthetic/private-source.png"));
            testCase.verifyTrue(contains(fallback, ...
                "Synthetic incident at /synthetic/private-source.png."));
            testCase.verifyTrue(contains(fallback, ...
                "app-state-compact.mat could not be represented"));
            clear cleanup
        end

        function automaticExportUsesArtifactsAndDoesNotAskForAPath(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            definition = bundleDefinition();
            backend = struct( ...
                "chooseOutputFile", @failOutputDialog, ...
                "alert", @(~, ~) []);
            runtime = labkit.app.internal.runtime.RuntimeFactory.createHeadless( ...
                definition, [], backend, [], JournalRoot=folder);
            cleanup = onCleanup(@() runtime.close());

            destination = runtime.exportDiagnosticBundleInteractive();
            fileCleanup = onCleanup(@() deleteIfFile(destination));

            testCase.verifyTrue(isfile(destination));
            testCase.verifyTrue(endsWith(destination, ".zip"));
            testCase.verifyTrue(contains(destination, ...
                fullfile("artifacts", "diagnostics")));
            [~, filename, extension] = fileparts(destination);
            testCase.verifyTrue(startsWith( ...
                string(filename) + string(extension), ...
                "labkit-diagnostics-sensitive-compact-state-probe-diagnostic-bundle-"));
            unpacked = fullfile(folder, "compact-interactive");
            unzip(destination, unpacked);
            testCase.verifyTrue(isfile( ...
                fullfile(unpacked, "app-state-compact.mat")));
            report = jsondecode(fileread( ...
                fullfile(unpacked, "bundle-report.json")));
            testCase.verifyEqual(string(report.eventProjection), ...
                "complete-retained-events");
            testCase.verifyEqual(string(report.stateReview.mode), "compact");
            clear fileCleanup cleanup
        end

        function closeAfterErrorAutomaticallyExportsCompactBundle(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            artifacts = diagnosticArtifactsFolder();
            before = diagnosticFiles(artifacts);
            runtime = labkit.app.internal.runtime.RuntimeFactory.createHeadless( ...
                bundleDefinition(), [], struct(), [], JournalRoot=folder);
            runtime.invokeAction("run");
            runtime.setTraceCapture(false);

            runtime.close();

            created = setdiff(diagnosticFiles(artifacts), before);
            fileCleanup = onCleanup(@() deleteDiagnostics(artifacts, created));
            testCase.verifyNumElements(created, 1);
            testCase.verifyTrue(contains(created, ...
                "diagnostics-sensitive-compact-state"));
            unpacked = fullfile(folder, "automatic-close");
            unzip(fullfile(artifacts, created), unpacked);
            testCase.verifyTrue(isfile( ...
                fullfile(unpacked, "app-state-compact.mat")));
            events = readEvents(unpacked);
            names = string({events.eventName});
            testCase.verifyTrue(any(names == "analysis.failed"));
            testCase.verifyTrue(any(names == "runtime.close.completed"));
            clear fileCleanup
        end

        function cleanCloseDoesNotAutomaticallyExportBundle(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            artifacts = diagnosticArtifactsFolder();
            before = diagnosticFiles(artifacts);
            runtime = labkit.app.internal.runtime.RuntimeFactory.createHeadless( ...
                bundleDefinition(), [], struct(), [], JournalRoot=folder);

            runtime.close();

            created = setdiff(diagnosticFiles(artifacts), before);
            fileCleanup = onCleanup(@() deleteDiagnostics(artifacts, created));
            testCase.verifyEmpty(created);
            clear fileCleanup
        end
    end
end

function definition = bundleDefinition()
layout = labkit.app.layout.workbench({ ...
    labkit.app.layout.button( ...
        "run", "Run", @emitBundleIncident, ...
        Tooltip="Generate a synthetic diagnostic incident."), ...
    labkit.app.layout.button( ...
        "largeState", "Large state", @emitLargeState, ...
        Tooltip="Generate a large synthetic diagnostic state.")});
definition = labkit.app.Definition( ...
    Entrypoint="labkit_DiagnosticBundleProbe_app", ...
    AppId="probe.diagnostic-bundle", ...
    Title="Diagnostic bundle probe", Family="Tests", ...
    AppVersion="1.0.0", Updated="2026-07-26", ...
    Requirements=[], Workbench=layout);
end

function applicationState = emitLargeState( ...
        applicationState, ~)
stream = RandStream("mt19937ar", "Seed", 41);
applicationState.session.cache = struct( ...
    "largePayload", uint8(randi(stream, 256, 1100, 1100) - 1), ...
    "smallDiagnosticValues", [2, 3, 5, 7]);
end

function applicationState = emitBundleIncident( ...
        applicationState, callbackContext)
category = "app.probe.diagnostic-bundle.analysis";
callbackContext.log( ...
    "debug", "analysis.branch_selected", ...
    "Synthetic branch selected.", ...
    Category=category, Audience="developer", ...
    Attributes=struct("enum", "synthetic"));
callbackContext.log( ...
    "info", "analysis.completed", ...
    "Synthetic analysis completed for /synthetic/private-source.png.", ...
    Category=category, Audience="user", ...
    Attributes=struct("sourcePath", "/synthetic/private-source.png"));
callbackContext.log( ...
    "error", "analysis.failed", ...
    "Synthetic analysis failed.", ...
    Category=category, Audience="user", ...
    Exception=MException( ...
        "labkit:test:SyntheticIncident", ...
        "Synthetic incident at /synthetic/private-source.png."));
end

function events = readEvents(folder)
lines = readlines(fullfile(folder, "events.jsonl"), ...
    EmptyLineRule="skip");
events = repmat(jsondecode(lines(1)), numel(lines), 1);
for index = 1:numel(lines)
    events(index) = jsondecode(lines(index));
end
end

function value = readAllBundleText(folder, files)
value = strings(numel(files), 1);
for index = 1:numel(files)
    value(index) = string(fileread( ...
        fullfile(folder, files(index))));
end
end

function failJournalInitialize(stage)
if string(stage) == "initialize"
    error("labkit:test:JournalInitializeFailure", ...
        "Intentional initialization failure.");
end
end

function deleteIfFile(filepath)
if isfile(filepath)
    delete(filepath);
end
end

function folder = diagnosticArtifactsFolder()
versionPath = string(which("labkit.app.version"));
root = string(fileparts(fileparts(fileparts(versionPath))));
folder = fullfile(root, "artifacts", "diagnostics");
end

function files = diagnosticFiles(folder)
files = strings(0, 1);
if exist(char(folder), "dir") ~= 7
    return
end
listing = dir(fullfile(folder, ...
    "labkit-diagnostics-*-probe-diagnostic-bundle-*.zip"));
files = string({listing.name}).';
end

function deleteDiagnostics(folder, files)
for index = 1:numel(files)
    deleteIfFile(fullfile(folder, files(index)));
end
end

function choice = failOutputDialog(varargin)
choice = MException("labkit:test:OutputDialogFailure", ...
    "Intentional output dialog failure.");
throw(choice);
end
