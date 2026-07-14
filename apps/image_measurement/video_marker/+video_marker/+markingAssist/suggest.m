%SUGGEST Build editable draft points from one lightweight assist mode.
% Expected caller: definitionActions. Mode is interpolate or trackPrevious;
% reader is required only for tracking. Returns points and an app-log message.
function [points, message] = suggest(mode, state, reader)
    mode = string(mode);
    available = video_marker.markingAssist.availability(state);
    if mode == "interpolate"
        [points, bounds] = video_marker.frameAnnotations.interpolatedPoints( ...
            state.annotations, state.currentFrame);
        if ~available.interpolate
            error('labkit_VideoMarker_app:InterpolationUnavailable', ...
                'The current frame needs confirmed annotations before and after it.');
        end
        message = sprintf('Interpolated frame %d from confirmed frames %d and %d.', ...
            state.currentFrame, bounds(1), bounds(2));
        return;
    end
    if mode == "trackPrevious"
        if ~available.trackPrevious
            error('labkit_VideoMarker_app:TrackingUnavailable', ...
                'The immediately previous frame must have complete confirmed points.');
        end
        previousImage = video_marker.videoSource.readFrame(reader, state.currentFrame - 1);
        previousPoints = video_marker.frameAnnotations.framePoints( ...
            state.annotations, state.currentFrame - 1);
        points = video_marker.motionEstimate.trackPoints( ...
            previousImage, state.currentImage, previousPoints);
        message = sprintf(['Estimated frame %d points from frame %d by ' ...
            'local block matching.'], state.currentFrame, state.currentFrame - 1);
        return;
    end
    error('labkit_VideoMarker_app:UnknownMarkingAssist', ...
        'Unknown marking-assist mode.');
end
