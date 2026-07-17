function varargout = labkit_VideoMarker_app(varargin)
%LABKIT_VIDEOMARKER_APP Manually mark ordered feature points across video frames.
% Thin entrypoint delegates requests, launch, and version title to runtime V2.
    [varargout{1:nargout}] = labkit.ui.runtime.launch( ...
        @video_marker.definition, varargin{:});
end
