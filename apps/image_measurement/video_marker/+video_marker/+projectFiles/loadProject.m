%LOADPROJECT Load a Video Marker project MAT file.
% Expected caller: project open action. The project contains no UI handles.
function state = loadProject(filepath)
    data = load(filepath, 'videoMarkerProject');
    if ~isfield(data, 'videoMarkerProject')
        error('labkit_VideoMarker_app:InvalidProject', 'Project file is missing videoMarkerProject.');
    end
    state = data.videoMarkerProject;
    if ~isfield(state, 'schemaVersion') || state.schemaVersion ~= 1
        error('labkit_VideoMarker_app:InvalidProject', 'Unsupported Video Marker project schema.');
    end
    state.currentImage = [];
end
