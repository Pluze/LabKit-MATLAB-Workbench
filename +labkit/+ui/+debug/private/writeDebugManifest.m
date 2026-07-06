% Expected caller: labkit.ui.debug.context. Inputs are a manifest path,
% sample-pack manifest, and debug metadata. Side effect: writes manifest JSON.
function writeDebugManifest(filepath, manifest, metadata)
    if nargin < 2 || isempty(manifest)
        manifest = struct();
    end
    if ~isstruct(manifest)
        manifest = struct("value", string(manifest));
    end

    payload = manifest;
    payload.debug = metadata;
    text = jsonencode(payload, "PrettyPrint", true);

    folder = string(fileparts(char(filepath)));
    ensureDirectory(folder);
    fid = fopen(char(filepath), "w", "n", "UTF-8");
    if fid < 0
        error('labkit:ui:DebugManifestWriteFailed', ...
            'Could not write debug manifest file: %s.', filepath);
    end
    cleaner = onCleanup(@() fclose(fid));
    fprintf(fid, "%s\n", char(string(text)));
end

function ensureDirectory(folder)
    folder = string(folder);
    if strlength(folder) == 0
        return;
    end
    if exist(char(folder), "dir") ~= 7
        mkdir(char(folder));
    end
end
