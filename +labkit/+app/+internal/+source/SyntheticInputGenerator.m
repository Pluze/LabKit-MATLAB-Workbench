classdef (Hidden, Sealed) SyntheticInputGenerator
    % Private validation and publication boundary for App synthetic inputs.

    methods (Static)
        function pack = generate(definition, folder)
            if ~isa(definition, "labkit.app.Definition") || ~isscalar(definition)
                error("labkit:app:runtime:InvariantFailure", ...
                    "SyntheticInputGenerator requires one Definition.");
            end
            if isempty(definition.BuildSyntheticSample)
                error("labkit:app:contract:UnsupportedOperation", ...
                    "Definition does not declare BuildSyntheticSample.");
            end
            if isempty(definition.ProjectSchema)
                error("labkit:app:contract:UnsupportedOperation", ...
                    "Synthetic inputs require ProjectSchema.");
            end
            context = labkit.app.synthetic.Context(folder);
            pack = definition.BuildSyntheticSample(context);
            if ~isa(pack, "labkit.app.synthetic.Pack") || ~isscalar(pack)
                error("labkit:app:contract:InvalidValue", ...
                    "BuildSyntheticSample must return one " + ...
                    "labkit.app.synthetic.Pack value.");
            end
            labkit.app.internal.source.SyntheticInputGenerator.validateProject( ...
                definition, pack);
            labkit.app.internal.source.SyntheticInputGenerator.verifyArtifacts( ...
                context, pack);
            labkit.app.internal.source.SyntheticInputGenerator.writeManifest( ...
                context, pack);
        end
    end

    methods (Static, Access = private)
        function validateProject(definition, pack)
            try
                accepted = definition.ProjectSchema.Validate( ...
                    pack.InitialProject);
            catch cause
                failure = MException( ...
                    "labkit:app:contract:InvalidValue", ...
                    "BuildSyntheticSample returned an invalid current project.");
                failure = addCause(failure, cause);
                throw(failure);
            end
            if ~isequal(accepted, true)
                error("labkit:app:contract:InvalidValue", ...
                    "BuildSyntheticSample returned an invalid current project.");
            end
        end

        function verifyArtifacts(context, pack)
            for index = 1:numel(pack.Artifacts)
                artifact = pack.Artifacts{index};
                if artifact.Expectation == "exports"
                    continue;
                end
                pathParts = cellstr(split(artifact.RelativePath, "/"));
                filepath = string(fullfile( ...
                    char(context.RootFolder), pathParts{:}));
                if exist(char(filepath), "file") ~= 2 && ...
                        exist(char(filepath), "dir") ~= 7
                    error("labkit:app:contract:InvalidValue", ...
                        "BuildSyntheticSample did not create artifact %s.", ...
                        artifact.Id);
                end
            end
        end

        function writeManifest(context, pack)
            artifacts = repmat(struct( ...
                "id", "", "role", "", "relativePath", "", ...
                "expectation", ""), 1, numel(pack.Artifacts));
            for index = 1:numel(pack.Artifacts)
                artifact = pack.Artifacts{index};
                artifacts(index) = struct( ...
                    "id", artifact.Id, ...
                    "role", artifact.Role, ...
                    "relativePath", artifact.RelativePath, ...
                    "expectation", artifact.Expectation);
            end
            payload = struct( ...
                "type", "labkit.synthetic-input-pack", ...
                "scenario", pack.Scenario, ...
                "artifacts", artifacts);
            filepath = string(fullfile( ...
                context.RootFolder, "synthetic-input-pack.json"));
            temporary = filepath + ".tmp";
            file = fopen(char(temporary), "w");
            if file < 0
                error("labkit:app:runtime:SyntheticInputWriteFailed", ...
                    "Could not write the synthetic-input manifest.");
            end
            cleanup = onCleanup(@() fclose(file));
            fprintf(file, "%s\n", jsonencode(payload, PrettyPrint=true));
            clear cleanup
            [moved, message] = movefile( ...
                char(temporary), char(filepath), "f");
            if ~moved
                error("labkit:app:runtime:SyntheticInputWriteFailed", ...
                    "Could not publish the synthetic-input manifest: %s", ...
                    message);
            end
        end
    end
end
