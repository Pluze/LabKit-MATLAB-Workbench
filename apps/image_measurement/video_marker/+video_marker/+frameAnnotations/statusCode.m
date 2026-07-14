%STATUSCODE Convert a frame-status name to the stored uint8 code.
% Expected caller: annotation helpers and CSV import.
function code = statusCode(name)
    names = video_marker.frameAnnotations.statusNames();
    idx = find(names == string(name), 1);
    if isempty(idx)
        error('labkit_VideoMarker_app:InvalidFrameStatus', 'Unknown frame status.');
    end
    code = uint8(idx - 1);
end
