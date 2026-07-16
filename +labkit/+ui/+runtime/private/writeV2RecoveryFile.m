% Private Runtime V2 recovery writer. Expected callers are the debounced
% autosave scheduler and the injected project.saveAutosave service. Input is a
% current runtime snapshot. Side effect atomically writes the current recovery
% generation while retaining at most one previous generation.
function filepath = writeV2RecoveryFile(runtime)
    folder = recoveryFolder(runtime);
    if ~isfolder(folder)
        mkdir(folder);
    end
    filepath = string(fullfile(folder, "recovery.mat"));
    previous = string(fullfile(folder, "previous.mat"));
    if isfile(filepath)
        [copied, message] = copyfile(filepath, previous, 'f');
        if ~copied
            error('labkit:ui:runtime:RecoveryWriteFailed', ...
                'Could not retain the previous recovery generation: %s.', ...
                message);
        end
    end
    envelope = createV2ProjectEnvelope(runtime, [], filepath);
    writeV2ProjectFile(filepath, envelope);
end

function folder = recoveryFolder(runtime)
    root = "";
    if isstruct(runtime.request) && isfield(runtime.request, 'recoveryRoot')
        root = string(runtime.request.recoveryRoot);
    end
    if strlength(root) == 0
        root = fullfile(prefdir, "LabKit", "recovery");
    end
    folder = string(fullfile(root, appStorageKey(runtime.definition.id), ...
        char(runtime.document.id)));
end
