function varargout = focusStackWorkflow(command, varargin)
%FOCUSSTACKWORKFLOW Dispatch app-owned focus-stack helpers.
% Expected caller: focus-stack app tests and migration-time workflow checks.
% Inputs are a workflow command plus command-specific arguments. Outputs match
% the selected app-private helper. This helper has no file side effects.

    switch string(command)
        case "computeFocusStack"
            varargout{1} = computeFocusStack(varargin{1}, varargin{2});
        case "buildFocusStackSummaryTable"
            varargout{1} = buildFocusStackSummaryTable(varargin{1}, ...
                string(varargin{2}));
        case "findFocusStackImages"
            varargout{1} = findFocusStackImages(string(varargin{1}));
        case "selectedFocusImagePaths"
            varargout{1} = selectedFocusImagePaths(varargin{1}, varargin{2});
        case "alignFocusStackImages"
            [varargout{1:nargout}] = alignFocusStackImages(varargin{1});
        otherwise
            error('labkit:FocusStack:UnknownWorkflowCommand', ...
                'Unknown focus-stack workflow helper command: %s.', command);
    end
end
