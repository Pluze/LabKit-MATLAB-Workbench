classdef (Hidden, Sealed) Store
    % Own App-specific artifact naming and repository scratch destinations.
    % Callers: RuntimeKernel and SessionJournal. Inputs are domain-neutral
    % artifact tokens; paths remain below the checkout's ignored artifacts
    % directory.

    properties (Access = private)
        AppId (1, 1) string
    end

    methods
        function obj = Store(appId)
            obj.AppId = artifactToken(appId, "App ID");
        end

        function destination = destination(obj, category, stem, extension)
            filename = obj.filename(stem, extension);
            folder = labkit.app.internal.artifact.Store.folder(category);
            if exist(char(folder), "dir") ~= 7
                [created, message] = mkdir(char(folder));
                if ~created
                    error("labkit:app:runtime:ArtifactWriteFailed", ...
                        "Could not create the LabKit artifacts folder: %s", ...
                        message);
                end
            end
            destination = fullfile(folder, filename);
        end

        function filename = filename(obj, stem, extension)
            stem = artifactToken(stem, "stem");
            extension = string(extension);
            if ~isscalar(extension) || ...
                    isempty(regexp(char(extension), ...
                    '^\.[a-z0-9]+$', "once"))
                error("labkit:app:runtime:InvariantFailure", ...
                    "Artifact extension must be a lowercase file extension.");
            end
            timestamp = string(datetime("now", TimeZone="UTC", ...
                Format="yyyyMMdd-HHmmss"));
            nonce = extractBefore( ...
                labkit.app.internal.identity.newId(), 9);
            filename = "labkit-" + stem + "-" + obj.AppId + "-" + ...
                timestamp + "-" + nonce + extension;
        end
    end

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
