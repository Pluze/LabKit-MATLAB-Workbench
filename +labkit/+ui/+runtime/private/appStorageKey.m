% Private Runtime V2 identity helper. Expected callers are recovery readers
% and writers. Input is one validated app id. Output is a reversible,
% filesystem-safe UTF-8 hex key, so distinct app ids cannot share storage.
function key = appStorageKey(appId)
    appId = string(appId);
    if ~isscalar(appId) || strlength(appId) == 0
        error('labkit:ui:runtime:InvalidAppId', ...
            'App id must be nonempty scalar text.');
    end
    bytes = unicode2native(char(appId), 'UTF-8');
    key = "app_" + lower(string(reshape(dec2hex(bytes, 2).', 1, [])));
end
