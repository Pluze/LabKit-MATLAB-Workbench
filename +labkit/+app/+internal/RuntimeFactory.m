classdef (Hidden, Sealed) RuntimeFactory
    % Internal runtime and synthetic-diagnostic construction boundary.

    methods (Static)
        function runtime = createHeadless( ...
                definition, initialProject, backend, diagnostics, journal, varargin)
            if nargin < 2
                initialProject = [];
            end
            if nargin < 3
                backend = struct();
            end
            if nargin < 4
                diagnostics = labkit.app.diagnostic.Options();
            end
            if nargin < 5
                journal = [];
            end
            journalRoot = parseJournalRoot(journal, varargin{:});
            runtime = labkit.app.internal.RuntimeFactory.create( ...
                definition, initialProject, backend, ...
                "headless", diagnostics, journal, journalRoot);
        end

        function runtime = createMatlab( ...
                definition, initialProject, backend, diagnostics, journal, varargin)
            if nargin < 2
                initialProject = [];
            end
            if nargin < 3
                backend = struct();
            end
            if nargin < 4
                diagnostics = labkit.app.diagnostic.Options();
            end
            if nargin < 5
                journal = [];
            end
            journalRoot = parseJournalRoot(journal, varargin{:});
            runtime = labkit.app.internal.RuntimeFactory.create( ...
                definition, initialProject, backend, ...
                "matlab", diagnostics, journal, journalRoot);
        end
    end

    methods (Static, Access = private)
        function runtime = create( ...
                definition, initialProject, backend, platform, diagnostics, journal, journalRoot)
            if ~isa(definition, "labkit.app.Definition") || ...
                    ~isscalar(definition)
                error("labkit:app:runtime:InvariantFailure", ...
                    "RuntimeFactory requires one Definition.");
            end
            journal = prepareJournal(definition, journal, journalRoot);
            try
                projection = labkit.app.internal.SessionJournalProjection(journal);
                stream = labkit.app.internal.SessionEventStream(definition, ...
                    SessionId=journal.sessionId(), ProjectionHook=@projection.project, ...
                    ProjectionHealthHook=@projection.drainHealth);
                recorder = labkit.app.internal.SessionDiagnostics( ...
                    definition, stream, projection, journal);
            catch cause
                try
                    journal.close();
                catch
                    % Journal teardown must not hide the construction failure.
                end
                rethrow(cause);
            end
            sampleOperation = [];
            try
                if diagnostics.Sample == "synthetic"
                    sampleOperation = recorder.begin( ...
                        "sample", "synthetic", "build");
                    buildSyntheticSample( ...
                        definition, initialProject, diagnostics);
                    initialProject = [];
                    recorder.finish(sampleOperation, "completed", "notApplicable", []);
                    sampleOperation = [];
                end
                runtime = labkit.app.internal.RuntimeKernel( ...
                    definition, definition.Compiled, initialProject, ...
                    backend, platform, diagnostics, recorder);
            catch cause
                if ~isempty(sampleOperation)
                    recorder.finish(sampleOperation, "failed", "notApplicable", cause);
                end
                recorder.close();
                rethrow(cause);
            end
        end
    end
end

function journal = prepareJournal(definition, journal, journalRoot)
if isempty(journal)
    if strlength(journalRoot) == 0
        journal = labkit.app.internal.SessionJournal(definition);
    else
        journal = labkit.app.internal.SessionJournal(definition, ...
            RootFolder=journalRoot);
    end
    return;
end
if ~isa(journal, "labkit.app.internal.SessionJournal") || ~isscalar(journal)
    error("labkit:app:runtime:InvariantFailure", ...
        "RuntimeFactory journal seam requires one SessionJournal.");
end
end

function journalRoot = parseJournalRoot(journal, varargin)
journalRoot = "";
if isempty(varargin)
    return;
end
options = labkit.app.internal.OptionParser.parse( ...
    "RuntimeFactory", "JournalRoot", varargin{:});
if ~isfield(options, "JournalRoot")
    return;
end
if ~isempty(journal)
    error("labkit:app:runtime:InvariantFailure", ...
        "RuntimeFactory cannot combine an explicit journal with JournalRoot.");
end
value = options.JournalRoot;
if ~(ischar(value) || (isstring(value) && isscalar(value))) || ...
        strlength(strip(string(value))) == 0
    error("labkit:app:contract:InvalidValue", ...
        "RuntimeFactory JournalRoot must be nonempty scalar text.");
end
journalRoot = string(value);
end

function buildSyntheticSample( ...
        definition, initialProject, diagnostics)
if ~isempty(initialProject)
    error("labkit:app:contract:InvalidValue", ...
        "Definition launch cannot combine InitialProject with " + ...
        "a synthetic diagnostic sample.");
end
if strlength(diagnostics.ArtifactFolder) == 0
    error("labkit:app:contract:InvalidValue", ...
        "A synthetic diagnostic sample requires ArtifactFolder.");
end
if isempty(definition.BuildDebugSample)
    error("labkit:app:contract:UnsupportedOperation", ...
        "Definition does not declare BuildDebugSample.");
end
if isempty(definition.ProjectSchema)
    error("labkit:app:contract:UnsupportedOperation", ...
        "A synthetic diagnostic sample requires ProjectSchema.");
end
context = labkit.app.diagnostic.SampleContext(diagnostics.ArtifactFolder);
pack = definition.BuildDebugSample(context);
if ~isa(pack, "labkit.app.diagnostic.SamplePack") || ~isscalar(pack)
    error("labkit:app:contract:InvalidValue", ...
        "BuildDebugSample must return one " + ...
        "labkit.app.diagnostic.SamplePack value.");
end
try
    accepted = definition.ProjectSchema.Validate(pack.InitialProject);
catch cause
    failure = MException( ...
        "labkit:app:contract:InvalidValue", ...
        "BuildDebugSample returned an invalid current project.");
    failure = addCause(failure, cause);
    throw(failure);
end
if ~isequal(accepted, true)
    error("labkit:app:contract:InvalidValue", ...
        "BuildDebugSample returned an invalid current project.");
end
verifySampleArtifacts(context, pack);
writeSampleManifest(context, pack);
end

function verifySampleArtifacts(context, pack)
for k = 1:numel(pack.Artifacts)
    artifact = pack.Artifacts{k};
    if artifact.Expectation == "exports"
        continue;
    end
    pathParts = cellstr(split(artifact.RelativePath, "/"));
    filepath = string(fullfile( ...
        char(context.ArtifactFolder), pathParts{:}));
    if exist(char(filepath), "file") ~= 2 && ...
            exist(char(filepath), "dir") ~= 7
        error("labkit:app:contract:InvalidValue", ...
            "BuildDebugSample did not create artifact %s.", artifact.Id);
    end
end
end

function writeSampleManifest(context, pack)
artifacts = repmat(struct( ...
    "id", "", "role", "", "relativePath", "", ...
    "expectation", ""), 1, numel(pack.Artifacts));
for k = 1:numel(pack.Artifacts)
    artifact = pack.Artifacts{k};
    artifacts(k) = struct( ...
        "id", artifact.Id, ...
        "role", artifact.Role, ...
        "relativePath", artifact.RelativePath, ...
        "expectation", artifact.Expectation);
end
payload = struct( ...
    "type", "labkit.diagnostic.sample-pack", ...
    "scenario", pack.Scenario, ...
    "artifacts", artifacts);
filepath = string(fullfile(context.ArtifactFolder, "sample-pack.json"));
temporary = filepath + ".tmp";
file = fopen(char(temporary), "w");
if file < 0
    error("labkit:app:runtime:DiagnosticWriteFailed", ...
        "Could not write the diagnostic sample manifest.");
end
cleanup = onCleanup(@() fclose(file));
fprintf(file, "%s\n", jsonencode(payload, PrettyPrint=true));
clear cleanup
[moved, message] = movefile(char(temporary), char(filepath), "f");
if ~moved
    error("labkit:app:runtime:DiagnosticWriteFailed", ...
        "Could not publish the diagnostic sample manifest: %s", message);
end
end
