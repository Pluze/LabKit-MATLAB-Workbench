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
            context = labkit.app.synthetic.Context(folder);
            pack = definition.BuildSyntheticSample(context);
            if ~isa(pack, "labkit.app.synthetic.Pack") || ~isscalar(pack)
                error("labkit:app:contract:InvalidValue", ...
                    "BuildSyntheticSample must return one " + ...
                    "labkit.app.synthetic.Pack value.");
            end
            labkit.app.internal.source.SyntheticInputGenerator.verifyArtifacts( ...
                context, pack);
        end
    end

    methods (Static, Access = private)
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
    end
end
