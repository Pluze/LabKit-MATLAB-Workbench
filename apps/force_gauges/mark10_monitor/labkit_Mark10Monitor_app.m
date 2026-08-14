function varargout = labkit_Mark10Monitor_app(varargin)
%LABKIT_MARK10MONITOR_APP Monitor and record Mark-10 force and travel.

    [varargout{1:nargout}] = mark10_monitor.definition().launch(varargin{:});
end
