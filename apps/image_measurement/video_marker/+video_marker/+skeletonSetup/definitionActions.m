% Expected caller: video_marker.definitionActions. Output owns the editable
% skeleton action slice before a video locks its point/connection schema.
function actions = definitionActions()
    actions = struct( ...
        "useSkeletonPreset", @onUseSkeletonPreset, ...
        "keypointEdited", @onKeypointEdited, ...
        "keypointSelected", @onKeypointSelected, ...
        "addKeypoint", @onAddKeypoint, ...
        "removeKeypoint", @onRemoveKeypoint, ...
        "moveKeypointUp", @(state, event, services) ...
            moveKeypoint(state, event, services, -1), ...
        "moveKeypointDown", @(state, event, services) ...
            moveKeypoint(state, event, services, 1), ...
        "connectionSelected", @onConnectionSelected, ...
        "connectionEndpointChanged", @onConnectionEndpointChanged, ...
        "addConnection", @onAddConnection, ...
        "connectInOrder", @onConnectInOrder, ...
        "removeConnection", @onRemoveConnection);
end

function state = onUseSkeletonPreset(state, ~, services)
    if skeletonLocked(state)
        return;
    end
    presets = video_marker.userInterface.skeletonPresets();
    selected = string(state.session.selection.skeletonPreset);
    match = find([presets.label] == selected, 1, 'first');
    if isempty(match)
        return;
    end
    state.project.annotations.skeleton = ...
        video_marker.skeletonDefinition.fromParts( ...
        presets(match).pointNames, presets(match).edges);
    state = video_marker.skeletonSetup.normalizeSelection(state, true);
    state = services.workflow.log(state, ...
        "Applied skeleton preset: " + selected + ".");
end

function state = onKeypointEdited(state, event, services)
    if skeletonLocked(state)
        return;
    end
    indices = services.events.entries(event, "indices");
    value = services.events.entries(event, "newData");
    if numel(indices) ~= 2 || indices(2) ~= 2
        return;
    end
    try
        state.project.annotations.skeleton = ...
            video_marker.skeletonDefinition.renamePoint( ...
            state.project.annotations.skeleton, indices(1), value);
        state = video_marker.skeletonSetup.normalizeSelection(state);
        state = services.workflow.log(state, sprintf( ...
            'Renamed keypoint %d.', indices(1)));
    catch ME
        services.diagnostics.report('Invalid keypoint name', ME);
        services.dialogs.alert(ME.message, 'Invalid keypoint name');
    end
end

function state = onKeypointSelected(state, event, services)
    indices = services.events.entries(event, "indices");
    state.session.selection.selectedPointIndex = selectedRow(indices);
end

function state = onAddKeypoint(state, ~, services)
    if skeletonLocked(state)
        return;
    end
    [state.project.annotations.skeleton, index] = ...
        video_marker.skeletonDefinition.addPoint( ...
        state.project.annotations.skeleton);
    state.session.selection.selectedPointIndex = index;
    state = video_marker.skeletonSetup.normalizeSelection(state);
    state = services.workflow.log(state, ...
        "Added keypoint " + ...
        state.project.annotations.skeleton.pointNames(index) + ".");
end

function state = onRemoveKeypoint(state, ~, services)
    index = state.session.selection.selectedPointIndex;
    names = state.project.annotations.skeleton.pointNames;
    if skeletonLocked(state) || index < 1 || index > numel(names)
        return;
    end
    state.project.annotations.skeleton = ...
        video_marker.skeletonDefinition.removePoint( ...
        state.project.annotations.skeleton, index);
    state.session.selection.selectedPointIndex = min( ...
        index, numel(state.project.annotations.skeleton.pointNames));
    state.session.selection.selectedEdgeIndex = 0;
    state = video_marker.skeletonSetup.normalizeSelection(state);
    state = services.workflow.log(state, sprintf( ...
        'Removed keypoint %d.', index));
end

function state = moveKeypoint(state, ~, services, delta)
    index = state.session.selection.selectedPointIndex;
    names = state.project.annotations.skeleton.pointNames;
    if skeletonLocked(state) || index < 1 || index > numel(names)
        return;
    end
    [state.project.annotations.skeleton, index] = ...
        video_marker.skeletonDefinition.movePoint( ...
        state.project.annotations.skeleton, index, delta);
    state.session.selection.selectedPointIndex = index;
    state = video_marker.skeletonSetup.normalizeSelection(state);
    state = services.workflow.log(state, sprintf( ...
        'Moved keypoint to position %d.', index));
end

function state = onConnectionSelected(state, event, services)
    indices = services.events.entries(event, "indices");
    state.session.selection.selectedEdgeIndex = selectedRow(indices);
end

function state = onConnectionEndpointChanged(state, event, ~)
    target = string(event.target);
    if target == "connectionFrom"
        state.session.selection.connectionFrom = string(event.value);
    elseif target == "connectionTo"
        state.session.selection.connectionTo = string(event.value);
    end
    state = video_marker.skeletonSetup.normalizeSelection(state);
end

function state = onAddConnection(state, ~, services)
    names = string(state.project.annotations.skeleton.pointNames(:));
    if skeletonLocked(state) || numel(names) < 2
        return;
    end
    a = find(names == string(state.session.selection.connectionFrom), 1);
    b = find(names == string(state.session.selection.connectionTo), 1);
    if isempty(a) || isempty(b) || a == b
        services.dialogs.alert( ...
            'Choose two different keypoints.', 'Invalid connection');
        return;
    end
    state.project.annotations.skeleton = ...
        video_marker.skeletonDefinition.addEdge( ...
        state.project.annotations.skeleton, a, b);
    state.session.selection.selectedEdgeIndex = ...
        size(state.project.annotations.skeleton.edges, 1);
    state = services.workflow.log(state, ...
        "Connected " + names(a) + " to " + names(b) + ".");
end

function state = onConnectInOrder(state, ~, services)
    if skeletonLocked(state) || ...
            numel(state.project.annotations.skeleton.pointNames) < 2
        return;
    end
    state.project.annotations.skeleton = ...
        video_marker.skeletonDefinition.connectInOrder( ...
        state.project.annotations.skeleton);
    state.session.selection.selectedEdgeIndex = 0;
    state = services.workflow.log(state, ...
        "Connected adjacent keypoints in order.");
end

function state = onRemoveConnection(state, ~, services)
    index = state.session.selection.selectedEdgeIndex;
    edgeCount = size(state.project.annotations.skeleton.edges, 1);
    if skeletonLocked(state) || index < 1 || index > edgeCount
        return;
    end
    state.project.annotations.skeleton = ...
        video_marker.skeletonDefinition.removeEdge( ...
        state.project.annotations.skeleton, index);
    state.session.selection.selectedEdgeIndex = min( ...
        index, size(state.project.annotations.skeleton.edges, 1));
    state = services.workflow.log(state, sprintf( ...
        'Removed connection %d.', index));
end

function row = selectedRow(indices)
    row = 0;
    if ~isempty(indices)
        row = max(0, round(double(indices(1))));
    end
end

function tf = skeletonLocked(state)
    tf = state.session.cache.videoInfo.frameCount > 0;
end
