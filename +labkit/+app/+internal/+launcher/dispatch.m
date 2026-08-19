function varargout = dispatch(root, varargin)
%DISPATCH Route the installed launcher entry modes to focused owners.
% ROOT is the checkout or installed package root. Optional arguments select
% list, version, documentation, or the default GUI. No state is retained.

[mode, modeArgs] = ...
    labkit.app.internal.launcher.parseRequest(varargin);
switch mode
    case "list"
        varargout = {labkit.app.internal.launcher.appCatalog(root)};
    case "documentation"
        varargout = {labkit.app.internal.launcher.documentationPage( ...
            root, modeArgs.command, modeArgs.source)};
    case "version"
        varargout = {labkit.app.internal.launcher.launcherVersion()};
    otherwise
        if nargout > 1
            error("labkit:app:internal:launcher:TooManyOutputs", ...
                "Launcher dispatch returns at most one figure.");
        end
        fig = labkit.app.internal.launcher.createLauncher(root);
        if nargout == 1
            varargout = {fig};
        end
end
end
