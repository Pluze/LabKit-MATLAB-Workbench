function varargout = labkit_FigureStudio_app(varargin)
%LABKIT_FIGURESTUDIO_APP Inspect, style, and export MATLAB figures.

    [initialProject, launchArguments] = ...
        figure_studio.launchRequest(varargin);
    if isempty(initialProject)
        [varargout{1:nargout}] = ...
            figure_studio.definition().launch(launchArguments{:});
    else
        [varargout{1:nargout}] = ...
            figure_studio.definition().launch( ...
                InitialProject=initialProject);
    end
end
