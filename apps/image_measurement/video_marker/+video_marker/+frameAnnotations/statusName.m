%STATUSNAME Convert a stored frame-status code to text.
% Expected caller: UI and CSV export.
function name = statusName(code)
    names = video_marker.frameAnnotations.statusNames();
    idx = double(code) + 1;
    if idx < 1 || idx > numel(names)
        error('labkit_VideoMarker_app:InvalidFrameStatus', 'Unknown frame status.');
    end
    name = names(idx);
end
