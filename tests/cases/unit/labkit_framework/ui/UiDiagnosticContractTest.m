classdef UiDiagnosticContractTest < matlab.unittest.TestCase
    %UIDIAGNOSTICCONTRACTTEST Verify explicit diagnostic public values.

    methods (Test, TestTags = {'Unit'})
        function optionsRejectUnknownAndAmbiguousValues(testCase)
            setupLabKitTestPath();
            options = labkit.app.diagnostic.Options( ...
                Level="verbose", ArtifactFolder="diagnostics", ...
                Sample="synthetic");

            testCase.verifyEqual(options.Level, "verbose");
            testCase.verifyEqual(options.Sample, "synthetic");
            testCase.verifyTrue(meta.class.fromName( ...
                "labkit.app.diagnostic.Options").Sealed);
            testCase.verifyError(@() labkit.app.diagnostic.Options( ...
                Level="trace"), "labkit:app:contract:InvalidValue");
            testCase.verifyError(@() labkit.app.diagnostic.Options( ...
                Enabled=true), "labkit:app:contract:UnknownArgument");
        end

        function sampleValuesStayInsideTheDiagnosticRoot(testCase)
            setupLabKitTestPath();
            root = string(tempname);
            cleanup = onCleanup(@() removeFolder(root));
            context = labkit.app.diagnostic.SampleContext(root);
            inputPath = context.samplePath("probe/input.csv");
            outputPath = context.outputPath("probe/output.csv");
            source = context.sourceRecord( ...
                "probe", "diagnosticInput", inputPath, true);
            artifact = context.artifact( ...
                "probeInput", "source", inputPath);
            pack = labkit.app.diagnostic.SamplePack( ...
                Scenario="representative", ...
                InitialProject=struct("inputs", struct("sources", source)), ...
                Artifacts={artifact});

            testCase.verifyTrue(startsWith(inputPath, context.SampleFolder));
            testCase.verifyTrue(startsWith(outputPath, context.OutputFolder));
            testCase.verifyEqual(pack.Artifacts{1}, artifact);
            testCase.verifyError(@() context.samplePath("../outside.csv"), ...
                "labkit:app:contract:InvalidValue");
            testCase.verifyError(@() context.artifact( ...
                "outside", "source", string(tempname)), ...
                "labkit:app:contract:InvalidValue");
            testCase.verifyError(@() labkit.app.diagnostic.Artifact( ...
                "bad", "source", "../outside.csv"), ...
                "labkit:app:contract:InvalidValue");
            duplicate = labkit.app.diagnostic.Artifact( ...
                "probeInput", "other", "samples/probe/other.csv");
            testCase.verifyError(@() labkit.app.diagnostic.SamplePack( ...
                Scenario="representative", InitialProject=struct(), ...
                Artifacts={artifact, duplicate}), ...
                "labkit:app:contract:DuplicateId");
            clear cleanup
        end

        function verboseRuntimeRecordsSemanticTransactions(testCase)
            setupLabKitTestPath();
            root = string(tempname);
            cleanupFolder = onCleanup(@() removeFolder(root));
            definition = diagnosticDefinition(@incrementState);
            options = labkit.app.diagnostic.Options( ...
                Level="verbose", ArtifactFolder=root);
            runtime = labkit.app.internal.RuntimeFactory.createHeadless( ...
                definition, [], struct(), options);
            cleanupRuntime = onCleanup(@() runtime.close());

            runtime.invokeAction("run");
            events = runtime.diagnosticEvents();
            callbackEvents = events( ...
                string({events.Category}) == "callback");
            appEvents = events(string({events.Category}) == "app");

            testCase.verifyTrue(any( ...
                string({callbackEvents.Outcome}) == "begin"));
            testCase.verifyTrue(any( ...
                string({callbackEvents.Outcome}) == "completed"));
            testCase.verifyTrue(any( ...
                string({appEvents.TargetId}) == "probe.increment"));
            countEvent = appEvents( ...
                string({appEvents.TargetId}) == "probe.count");
            testCase.verifyEqual(countEvent.Count, 1);
            testCase.verifyTrue(isfile(fullfile(root, "events.jsonl")));
            testCase.verifyTrue(isfile(fullfile(root, "manifest.json")));
            testCase.verifyFalse(isfile( ...
                fullfile(root, "active-operation.json")));
            runtime.close();
            manifest = jsondecode(fileread(fullfile(root, "manifest.json")));
            testCase.verifyEqual(string(manifest.status), "closed");
            clear cleanupRuntime cleanupFolder
        end

        function failedRuntimeTransactionIsSanitizedAndRethrown(testCase)
            setupLabKitTestPath();
            root = string(tempname);
            cleanupFolder = onCleanup(@() removeFolder(root));
            definition = diagnosticDefinition(@failWithSensitivePath);
            options = labkit.app.diagnostic.Options( ...
                Level="verbose", ArtifactFolder=root);
            runtime = labkit.app.internal.RuntimeFactory.createHeadless( ...
                definition, [], struct(), options);
            cleanupRuntime = onCleanup(@() runtime.close());

            testCase.verifyError(@() runtime.invokeAction("run"), ...
                "labkit:app:runtime:ActionFailed");
            events = runtime.diagnosticEvents();
            rollback = events( ...
                string({events.Outcome}) == "rolledBack");
            testCase.verifyNumElements(rollback, 1);
            testCase.verifyEqual(rollback.ErrorId, "probe:SensitiveFailure");
            testCase.verifyFalse(contains( ...
                rollback.ErrorMessage, "ExampleUser"));
            testCase.verifyFalse(contains( ...
                rollback.ErrorMessage, "sample.csv"));
            clear cleanupRuntime cleanupFolder
        end

        function syntheticSampleBuildsTheCurrentProjectBeforeStartup(testCase)
            setupLabKitTestPath();
            root = string(tempname);
            cleanupFolder = onCleanup(@() removeFolder(root));
            definition = syntheticDefinition();
            options = labkit.app.diagnostic.Options( ...
                Level="verbose", ArtifactFolder=root, ...
                Sample="synthetic");
            runtime = labkit.app.internal.RuntimeFactory.createHeadless( ...
                definition, [], struct(), options);
            cleanupRuntime = onCleanup(@() runtime.close());

            testCase.verifyEqual( ...
                string(runtime.State.project.inputs.sources.role), ...
                "diagnosticInput");
            testCase.verifyTrue(isfile(fullfile(root, "sample-pack.json")));
            manifest = jsondecode(fileread( ...
                fullfile(root, "sample-pack.json")));
            testCase.verifyEqual(string(manifest.scenario), "probe");
            testCase.verifyFalse(isfield(manifest, "initialProject"));
            events = runtime.diagnosticEvents();
            sampleEvents = events( ...
                string({events.Category}) == "sample");
            testCase.verifyEqual( ...
                string({sampleEvents.Outcome}), ["begin", "completed"]);
            testCase.verifyError(@() ...
                labkit.app.internal.RuntimeFactory.createHeadless( ...
                    definition, definition.ProjectSchema.Create(), ...
                    struct(), options), ...
                "labkit:app:contract:InvalidValue");
            clear cleanupRuntime cleanupFolder
        end
    end
end

function definition = diagnosticDefinition(callback)
layout = labkit.app.layout.workbench({ ...
    labkit.app.layout.tab("main", "Main", { ...
        labkit.app.layout.section("actions", "Actions", { ...
            labkit.app.layout.button("run", "Run", callback)})})});
definition = labkit.app.Definition( ...
    Entrypoint="labkit_DiagnosticProbe_app", ...
    AppId="diagnostic.probe", Title="Diagnostic Probe", ...
    Family="Tests", AppVersion="1.0.0", Updated="2026-07-19", ...
    Requirements=[], Workbench=layout);
end

function definition = syntheticDefinition()
schema = labkit.app.project.Schema( ...
    Version=1, Create=@createSyntheticProject, ...
    Validate=@validateSyntheticProject);
definition = labkit.app.Definition( ...
    Entrypoint="labkit_DiagnosticSampleProbe_app", ...
    AppId="diagnostic.sample.probe", Title="Diagnostic Sample Probe", ...
    Family="Tests", AppVersion="1.0.0", Updated="2026-07-19", ...
    Requirements=[], Workbench=labkit.app.layout.workbench({}), ...
    ProjectSchema=schema, BuildDebugSample=@buildSyntheticSample);
end

function project = createSyntheticProject()
project = struct("inputs", struct("sources", struct([])));
end

function accepted = validateSyntheticProject(project)
accepted = isstruct(project) && isscalar(project) && ...
    isfield(project, "inputs") && ...
    isfield(project.inputs, "sources");
end

function pack = buildSyntheticSample(context)
filepath = context.samplePath("probe/input.txt");
file = fopen(filepath, "w");
if file < 0
    error("probe:WriteFailed", "Could not write synthetic input.");
end
cleanup = onCleanup(@() fclose(file));
fprintf(file, "anonymous synthetic input\n");
clear cleanup
project = createSyntheticProject();
project.inputs.sources = context.sourceRecord( ...
    "probe", "diagnosticInput", filepath, true);
pack = labkit.app.diagnostic.SamplePack( ...
    Scenario="probe", InitialProject=project, ...
    Artifacts={context.artifact("probe", "source", filepath)});
end

function state = incrementState(state, context)
state.session.count = fieldOrDefault(state.session, "count", 0) + 1;
context.diagnosticCheckpoint("probe.increment");
context.diagnosticCount("probe.count", state.session.count);
end

function state = failWithSensitivePath(state, ~)
syntheticPath = fullfile("C:", "Users", "ExampleUser", "sample.csv");
error("probe:SensitiveFailure", "%s", ...
    "Could not read " + syntheticPath);
end

function value = fieldOrDefault(value, name, fallback)
if isfield(value, name)
    value = value.(name);
else
    value = fallback;
end
end

function removeFolder(folder)
if isfolder(folder)
    rmdir(folder, "s");
end
end
