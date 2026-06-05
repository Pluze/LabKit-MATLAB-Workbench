function debugLog = createAppDebugLog(appName, opts)
%CREATEAPPDEBUGLOG Deprecated wrapper for createDebugContext.
%
% Usage:
%   debugLog = labkit.ui.createAppDebugLog(appName, opts);
%
% This compatibility surface is retained for one migration cycle. New app
% code should call labkit.ui.createDebugContext so debug launch, trace, and
% callback instrumentation all use the current UI diagnostics contract.

    if nargin < 2
        opts = struct();
    end
    debugLog = labkit.ui.createDebugContext(appName, opts);
end
