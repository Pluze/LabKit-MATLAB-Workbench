function varargout = gamrywb_CIC_app(varargin)
%GAMRYWB_CIC_APP Package-backed CIC voltage-transient app entry point.
% GUI for calculating CIC from Gamry MULTI_STEP_CHRONOPOT .DTA files.

    [varargout{1:nargout}] = launchCICApp(varargin{:});
end
