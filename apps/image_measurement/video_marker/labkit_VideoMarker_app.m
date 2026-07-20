function varargout = labkit_VideoMarker_app(varargin)
%LABKIT_VIDEOMARKER_APP Manually mark ordered feature points across video frames.
% Thin entrypoint delegates requests, launch, and version title to the App SDK.
    [varargout{1:nargout}] = video_marker.definition().launch(varargin{:});
end
