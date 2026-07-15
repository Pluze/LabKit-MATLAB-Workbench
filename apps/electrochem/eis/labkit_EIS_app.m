function varargout = labkit_EIS_app(varargin)
%LABKIT_EIS_APP EIS overlay/export app.
% Single-file app that composes +labkit GUI/DTA APIs and owns EIS workflow choices.

    [varargout{1:nargout}] = labkit.ui.runtime.launch( ...
        @eis.definition, @eis.requirements, @eis.version, varargin{:});
end
