classdef SessionDiagnosticBundleSpec < matlab.unittest.TestCase
    % SESSIONDIAGNOSTICBUNDLESPEC Regression: explicit diagnostic export produces one privacy-safe complete ZIP from the current ordinary session.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function exportsTheExactSafeBundleFromAnActiveSession(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            definition = bundleDefinition();
            runtime = labkit.app.internal.RuntimeFactory.createHeadless( ...
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
                "redaction-report.json"
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
            redaction = jsondecode(fileread( ...
                fullfile(unpacked, "redaction-report.json")));
            testCase.verifyEqual( ...
                string(redaction.exportProjection), ...
                "canonical-safe-events-only");
            testCase.verifyTrue(any( ...
                string(redaction.excludedData) == "scientific-data"));

            bundleText = join(readAllBundleText( ...
                unpacked, expected), newline);
            testCase.verifyFalse(contains(bundleText, string(folder)));
            testCase.verifyFalse(contains(bundleText, "private-source.png"));
            clear cleanup
        end

        function fallsBackToSafeMemoryWhenTheJournalIsUnavailable(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            definition = bundleDefinition();
            journal = labkit.app.internal.SessionJournal( ...
                definition, RootFolder=folder, ...
                SessionId="session-bundle-fallback", ...
                FaultInjector=@failJournalInitialize);
            runtime = labkit.app.internal.RuntimeFactory.createHeadless( ...
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

        function zipFailureWritesOneReadableTextFallback(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            definition = bundleDefinition();
            runtime = labkit.app.internal.RuntimeFactory.createHeadless( ...
                definition, [], struct(), [], JournalRoot=folder);
            cleanup = onCleanup(@() runtime.close());
            runtime.invokeAction("run");

            destination = runtime.exportDiagnosticBundle(fullfile( ...
                folder, "unavailable", "diagnostics.zip"));
            fileCleanup = onCleanup(@() deleteIfFile(destination));
            fallback = string(fileread(destination));

            testCase.verifyTrue(endsWith(destination, ".txt"));
            testCase.verifyTrue(isfile(destination));
            testCase.verifyTrue(contains( ...
                fallback, "LabKit Diagnostic Text Fallback"));
            testCase.verifyTrue(contains( ...
                fallback, "analysis.failed"));
            testCase.verifyTrue(contains( ...
                fallback, "diagnostics.bundle_exported.failed"));
            testCase.verifyTrue(contains(fallback, ...
                "labkit:app:runtime:DiagnosticWriteFailed"));
            testCase.verifyFalse(contains(fallback, string(folder)));
            testCase.verifyFalse(contains( ...
                fallback, "private-source.png"));
            clear fileCleanup cleanup
        end

        function saveDialogFailureStillWritesTheTextFallback(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            definition = bundleDefinition();
            backend = struct( ...
                "chooseOutputFile", @failOutputDialog, ...
                "alert", @(~, ~) []);
            runtime = labkit.app.internal.RuntimeFactory.createHeadless( ...
                definition, [], backend, [], JournalRoot=folder);
            cleanup = onCleanup(@() runtime.close());

            destination = runtime.exportDiagnosticBundleInteractive();
            fileCleanup = onCleanup(@() deleteIfFile(destination));
            fallback = string(fileread(destination));

            testCase.verifyTrue(isfile(destination));
            testCase.verifyTrue(endsWith(destination, ".txt"));
            testCase.verifyTrue(contains( ...
                fallback, "labkit:test:OutputDialogFailure"));
            clear fileCleanup cleanup
        end
    end
end

function definition = bundleDefinition()
layout = labkit.app.layout.workbench({ ...
    labkit.app.layout.button( ...
        "run", "Run", @emitBundleIncident, ...
        Tooltip="Generate a synthetic diagnostic incident.")});
definition = labkit.app.Definition( ...
    Entrypoint="labkit_DiagnosticBundleProbe_app", ...
    AppId="probe.diagnostic-bundle", ...
    Title="Diagnostic bundle probe", Family="Tests", ...
    AppVersion="1.0.0", Updated="2026-07-26", ...
    Requirements=[], Workbench=layout);
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
    "Synthetic analysis completed.", ...
    Category=category, Audience="user");
callbackContext.log( ...
    "error", "analysis.failed", ...
    "Synthetic analysis failed.", ...
    Category=category, Audience="user", ...
    Exception=MException( ...
        "labkit:test:SyntheticIncident", "Synthetic incident."));
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

function choice = failOutputDialog(varargin)
choice = [];
error("labkit:test:OutputDialogFailure", ...
    "Intentional output dialog failure.");
end
