function varargout = labkit_FigureStudio_app(varargin)
%LABKIT_FIGURESTUDIO_APP Inspect, style, and export MATLAB figures.

    [varargout{1:nargout}] = labkit.ui.runtime.launch( ...
        @figure_studio.definition, "RequestAdapter", ...
        @figure_studio.launchRequest, varargin{:});
end
