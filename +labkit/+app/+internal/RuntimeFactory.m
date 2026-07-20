classdef (Hidden, Sealed) RuntimeFactory
    % Internal runtime and synthetic-diagnostic construction boundary.

    methods (Static)
        function runtime = createHeadless( ...
                definition, initialProject, backend, diagnostics)
            if nargin < 2
                initialProject = [];
            end
            if nargin < 3
                backend = struct();
            end
            if nargin < 4
                diagnostics = labkit.app.diagnostic.Options();
            end
            runtime = labkit.app.internal.RuntimeFactory.create( ...
                definition, initialProject, backend, ...
                "headless", diagnostics);
        end

        function runtime = createMatlab( ...
                definition, initialProject, backend, diagnostics)
            if nargin < 2
                initialProject = [];
            end
            if nargin < 3
                backend = struct();
            end
            if nargin < 4
                diagnostics = labkit.app.diagnostic.Options();
            end
            runtime = labkit.app.internal.RuntimeFactory.create( ...
                definition, initialProject, backend, ...
                "matlab", diagnostics);
        end
    end

    methods (Static, Access = private)
        function runtime = create( ...
                definition, initialProject, backend, platform, diagnostics)
            if ~isa(definition, "labkit.app.Definition") || ...
                    ~isscalar(definition)
                error("labkit:app:runtime:InvariantFailure", ...
                    "RuntimeFactory requires one Definition.");
            end
            recorder = labkit.app.internal.DiagnosticRecorder( ...
                definition, diagnostics);
            sampleOperation = [];
            try
                if diagnostics.Sample == "synthetic"
                    sampleOperation = recorder.begin( ...
                        "sample", "synthetic", "build");
                    initialProject = buildSyntheticProject( ...
                        definition, initialProject, diagnostics);
                    recorder.finish(sampleOperation, "completed", []);
                    sampleOperation = [];
                end
                runtime = labkit.app.internal.RuntimeKernel( ...
                    definition, initialProject, backend, platform, ...
                    diagnostics, recorder);
            catch cause
                if ~isempty(sampleOperation)
                    recorder.finish(sampleOperation, "failed", cause);
                end
                recorder.close();
                rethrow(cause);
            end
        end
    end
end

function initialProject = buildSyntheticProject( ...
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
initialProject = pack.InitialProject;
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
