function varargout = invokeDiscoveredApp(app, varargin)
%INVOKEDISCOVEREDAPP Invoke one revalidated dynamic App entry.
% APP is one descriptor returned by discoverApps. Optional inputs are passed
% only after the command resolves to the discovered owning folder.

labkit.app.internal.discovery.addPathIfMissing(app.folder, "-end");
command = string(app.command);
resolved = string(which(char(command)));
expected = fullfile(string(app.folder), command + ".m");
if strlength(resolved) == 0 || exist(expected, "file") ~= 2 || ...
        normalizePath(resolved) ~= normalizePath(expected)
    error("labkit:app:internal:launcher:AppEntryMismatch", ...
        "Discovered App entry does not resolve from its owning folder: %s", ...
        command);
end
% Dynamic extension boundary: the command is derived from and revalidated
% against one discovered labkit_*_app.m file before invocation.
if nargout > 0
    [varargout{1:nargout}] = feval(char(command), varargin{:});
else
    feval(char(command), varargin{:});
end
end

function value = normalizePath(value)
value = labkit.app.internal.filesystem.absolutePath(value);
if ispc, value = lower(value); end
end
