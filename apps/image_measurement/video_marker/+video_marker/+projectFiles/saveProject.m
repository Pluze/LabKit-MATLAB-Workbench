%SAVEPROJECT Save a Video Marker project MAT file.
% Expected caller: project save action. The saved variable is videoMarkerProject.
function saveProject(filepath, state)
    filepath = string(filepath);
    wrapper = struct();
    wrapper.videoMarkerProject = serializableState(state);
    save(filepath, '-struct', 'wrapper');
end

function project = serializableState(state)
    project = state;
    if isfield(project, 'currentImage')
        project.currentImage = [];
    end
end
