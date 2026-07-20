% App-owned implementation for video_marker.videoSource.openResource within the video_marker product workflow.
function resource = openResource(videoPath)
%OPENRESOURCE Open one video and create its bounded decoded-frame cache.
[reader, info] = video_marker.videoSource.openVideo(videoPath);
cache = video_marker.videoSource.createDecodedFrameCache( ...
    @(index) video_marker.videoSource.readFrame(reader, index));
firstFrame = cache.readFrame(1);
cache.reset(1, firstFrame);
resource = struct("path", string(videoPath), ...
    "reader", reader, "info", info, "cache", cache, ...
    "firstFrame", firstFrame);
end
