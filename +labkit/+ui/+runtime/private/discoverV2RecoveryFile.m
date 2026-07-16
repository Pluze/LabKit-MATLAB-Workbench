% Private UI runtime helper. Expected caller: runV2App. Inputs are a v2
% definition and request. Output is the newest recovery document under the
% app-owned recovery root, or empty text. Discovery never opens a document;
% an explicit recoveryFile or confirmed recover request performs the load.
function filepath = discoverV2RecoveryFile(def, request)
    root = "";
    if isstruct(request) && isfield(request, 'recoveryRoot')
        root = string(request.recoveryRoot);
    end
    if strlength(root) == 0
        root = fullfile(prefdir, "LabKit", "recovery");
    end
    filepath = "";
    keys = [appStorageKey(def.id), ...
        string(matlab.lang.makeValidName(char(def.id)))];
    keys = unique(keys, 'stable');
    candidates = dir(fullfile(root, "__labkit_missing__", "*"));
    for k = 1:numel(keys)
        appFolder = fullfile(root, keys(k));
        if isfolder(appFolder)
            found = dir(fullfile(appFolder, "*", "recovery.mat"));
            candidates = [candidates; found(:)];
        end
    end
    if isempty(candidates)
        return;
    end
    [~, index] = max([candidates.datenum]);
    filepath = string(fullfile(candidates(index).folder, ...
        candidates(index).name));
end
