% Private UI runtime helper. Expected caller: snapshot save/load services. Input
% is candidate semantic app state. Side effect: throws a path-specific error
% if the value contains runtime handles, callbacks, listeners, or opaque
% objects that should not be persisted in a LabKit state snapshot.
function validateSerializableState(value)
    validateValue(value, "state");
end

function validateValue(value, path)
    if isa(value, 'function_handle')
        reject(path, 'function handle');
    end
    if isnumeric(value) || islogical(value) || isstring(value) || ...
            ischar(value) || isMissingValue(value)
        return;
    end
    if isgraphics(value)
        reject(path, 'graphics handle');
    end
    if isa(value, 'datetime') || isa(value, 'duration') || ...
            isa(value, 'calendarDuration') || isa(value, 'categorical')
        return;
    end
    if isstruct(value)
        rejectRuntimeLikeStruct(value, path);
        fields = fieldnames(value);
        for element = 1:numel(value)
            for k = 1:numel(fields)
                validateValue(value(element).(fields{k}), ...
                    path + "." + string(fields{k}));
            end
        end
        return;
    end
    if iscell(value)
        for k = 1:numel(value)
            validateValue(value{k}, path + "{" + string(k) + "}");
        end
        return;
    end
    if istable(value)
        names = string(value.Properties.VariableNames);
        for k = 1:numel(names)
            validateValue(value.(names(k)), path + "." + names(k));
        end
        return;
    end
    reject(path, "unsupported " + string(class(value)));
end

function tf = isMissingValue(value)
    tf = false;
    try
        tf = ismissing(value);
        tf = all(tf(:));
    catch
        tf = false;
    end
end

function rejectRuntimeLikeStruct(value, path)
    runtimeFields = ["definition", "state", "actions", "ui", "debug"];
    if all(isfield(value, runtimeFields))
        reject(path, 'LabKit runtime struct');
    end
end

function reject(path, reason)
    error('labkit:ui:runtime:UnserializableState', ...
        '%s is a %s and cannot be saved in a LabKit state snapshot.', ...
        char(path), char(string(reason)));
end
