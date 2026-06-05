function varargout = electrochemWorkflow(appKey, command, varargin)
%ELECTROCHEMWORKFLOW Dispatch app-owned electrochem workflow helpers.
% Expected caller: electrochem app tests and migration-time workflow checks.
% Inputs are an app key, a workflow command, and command-specific arguments.
% Outputs match the selected app-owned helper. Side effects are limited to CSV
% export commands and app-owned plot drawing commands on caller axes.

    switch string(appKey)
        case "chronoOverlay"
            [varargout{1:nargout}] = chronoOverlayWorkflow(command, varargin{:});
        case "cic"
            [varargout{1:nargout}] = cicWorkflow(command, varargin{:});
        case "csc"
            [varargout{1:nargout}] = cscWorkflow(command, varargin{:});
        case "eis"
            [varargout{1:nargout}] = eisWorkflow(command, varargin{:});
        case "vtResistance"
            [varargout{1:nargout}] = vtResistanceWorkflow(command, varargin{:});
        otherwise
            error('labkit:Electrochem:UnknownWorkflow', ...
                'Unknown electrochem workflow key: %s.', appKey);
    end
end
