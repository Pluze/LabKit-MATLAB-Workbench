classdef (Hidden, Sealed) Store
    % Resolve repository scratch destinations for SessionJournal.
    % Inputs are domain-neutral
    % artifact tokens; paths remain below the checkout's ignored artifacts
    % directory.

    methods (Static)
        function folder = folder(category)
            % Return one category folder beneath the active LabKit artifacts root.
            category = artifactToken(category, "category");
            folder = artifactFolder(category);
        end
    end
end

function folder = artifactFolder(category)
versionPath = string(which("labkit.app.version"));
root = string(fileparts(fileparts(fileparts(versionPath))));
folder = fullfile(root, "artifacts", category);
end

function value = artifactToken(value, label)
value = lower(strip(string(value)));
value = regexprep(value, "[^a-z0-9]+", "-");
value = regexprep(value, "(^-+|-+$)", "");
if ~isscalar(value) || strlength(value) == 0
    error("labkit:app:runtime:InvariantFailure", ...
        "Artifact %s must contain letters or digits.", label);
end
end
