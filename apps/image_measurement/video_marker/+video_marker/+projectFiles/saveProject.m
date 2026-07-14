%SAVEPROJECT Save a Video Marker project MAT file.
% Expected caller: project save action. The saved variable is videoMarkerProject.
function saveProject(filepath, state)
    filepath = string(filepath);
    videoMarkerProject = serializableState(state); %#ok<NASGU>
    save(filepath, 'videoMarkerProject');
end

function project = serializableState(state)
    project = state;
    if isfield(project, 'currentImage')
        project.currentImage = [];
    end
end
