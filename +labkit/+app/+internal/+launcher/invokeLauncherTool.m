function varargout = invokeLauncherTool(root, relativeFolder, name, varargin)
%INVOKELAUNCHERTOOL Adapt one allowlisted source-checkout maintainer tool.
% The tool folder is present only for the call unless it was already on the
% MATLAB path. Fixed handles keep every shipped dependency statically visible.

folder = fullfile(root, relativeFolder);
if exist(fullfile(folder, name + ".m"), "file") ~= 2
    error("labkit:app:internal:launcher:ToolUnavailable", ...
        "Tool is unavailable: %s", name);
end
added = labkit.app.internal.launcher.addPathIfMissing(folder, "-begin");
if added
    cleanup = onCleanup(@() rmpath(folder));
end
switch string(name)
    case "manageLabKitVersions"
        callable = @manageLabKitVersions;
    case "cleanLabKitArtifacts"
        callable = @cleanLabKitArtifacts;
    case "renderLabKitDocs"
        callable = @renderLabKitDocs;
    case "runCodecheckReport"
        callable = @runCodecheckReport;
    case "profileLabKitTarget"
        callable = @profileLabKitTarget;
    case "packageLabKitApp"
        callable = @packageLabKitApp;
    otherwise
        error("labkit:app:internal:launcher:UnknownTool", ...
            "Launcher tool is not allowlisted: %s", name);
end
if nargout > 0
    [varargout{1:nargout}] = callable(varargin{:});
else
    callable(varargin{:});
end
clear cleanup
end
