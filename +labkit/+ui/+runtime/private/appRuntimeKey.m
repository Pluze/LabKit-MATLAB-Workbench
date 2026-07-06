% Private UI runtime helper. Expected caller: runtime and snapshot services.
% Output is the single appdata key used for LabKit app runtime storage.
function key = appRuntimeKey()
    key = 'labkitUiAppRuntime';
end
