%SKELETONSETUPACTIONS App-owned handlers for the visual skeleton configurator.
% Expected caller: video_marker.definitionActions. Handlers edit only the
% serializable skeleton setup state and existing semantic controls.
function actions = skeletonSetupActions()
    actions = struct( ...
        'useSkeletonPreset', @onUseSkeletonPreset, ...
        'keypointEdited', @onKeypointEdited, ...
        'keypointSelected', @onKeypointSelected, ...
        'addKeypoint', @onAddKeypoint, ...
        'removeKeypoint', @onRemoveKeypoint, ...
        'moveKeypointUp', @(state, payload, services) movePoint(state, payload, services, -1), ...
        'moveKeypointDown', @(state, payload, services) movePoint(state, payload, services, 1), ...
        'connectionSelected', @onConnectionSelected, ...
        'connectionEndpointChanged', @onConnectionEndpointChanged, ...
        'addConnection', @onAddConnection, ...
        'connectInOrder', @onConnectInOrder, ...
        'removeConnection', @onRemoveConnection);
end

function state = onUseSkeletonPreset(state, ~, services)
    if locked(state)
        return;
    end
    selected = string(labkit.ui.control.getValue(services.ui, 'skeletonPreset'));
    presets = video_marker.userInterface.skeletonPresets();
    idx = find([presets.label] == selected, 1);
    if isempty(idx)
        return;
    end
    state.skeleton = video_marker.skeletonDefinition.fromParts( ...
        presets(idx).pointNames, presets(idx).edges);
    state.selectedPointIndex = 0;
    state.selectedEdgeIndex = 0;
    logMessage(services, sprintf('Applied skeleton preset: %s.', char(selected)));
end

function state = onKeypointEdited(state, payload, services)
    if locked(state)
        return;
    end
    indices = payload.event.indices;
    if numel(indices) ~= 2 || indices(2) ~= 2
        return;
    end
    try
        state.skeleton = video_marker.skeletonDefinition.renamePoint( ...
            state.skeleton, indices(1), payload.event.newData);
        logMessage(services, sprintf('Renamed keypoint %d.', indices(1)));
    catch ME
        reportError(services, 'Invalid keypoint name', ME);
    end
end

function state = onKeypointSelected(state, payload, ~)
    state.selectedPointIndex = selectedRow(payload.event.indices);
end

function state = onAddKeypoint(state, ~, services)
    if locked(state)
        return;
    end
    [state.skeleton, state.selectedPointIndex] = ...
        video_marker.skeletonDefinition.addPoint(state.skeleton);
    logMessage(services, sprintf('Added keypoint %s.', ...
        char(state.skeleton.pointNames(state.selectedPointIndex))));
end

function state = onRemoveKeypoint(state, ~, services)
    idx = state.selectedPointIndex;
    if locked(state) || idx < 1 || idx > numel(state.skeleton.pointNames)
        return;
    end
    state.skeleton = video_marker.skeletonDefinition.removePoint(state.skeleton, idx);
    state.selectedPointIndex = min(idx, numel(state.skeleton.pointNames));
    state.selectedEdgeIndex = 0;
    logMessage(services, sprintf('Removed keypoint %d.', idx));
end

function state = movePoint(state, ~, services, delta)
    idx = state.selectedPointIndex;
    if locked(state) || idx < 1 || idx > numel(state.skeleton.pointNames)
        return;
    end
    [state.skeleton, state.selectedPointIndex] = ...
        video_marker.skeletonDefinition.movePoint(state.skeleton, idx, delta);
    logMessage(services, sprintf('Moved keypoint to position %d.', ...
        state.selectedPointIndex));
end

function state = onConnectionSelected(state, payload, ~)
    state.selectedEdgeIndex = selectedRow(payload.event.indices);
end

function state = onConnectionEndpointChanged(state, ~, ~)
    % Rendering filters the opposite endpoint while preserving valid choices.
end

function state = onAddConnection(state, ~, services)
    names = state.skeleton.pointNames;
    if locked(state) || numel(names) < 2
        return;
    end
    a = find(names == string(labkit.ui.control.getValue(services.ui, 'connectionFrom')), 1);
    b = find(names == string(labkit.ui.control.getValue(services.ui, 'connectionTo')), 1);
    if isempty(a) || isempty(b) || a == b
        labkit.ui.runtime.showAlert(services.figure, ...
            'Choose two different keypoints.', 'Invalid connection');
        return;
    end
    state.skeleton = video_marker.skeletonDefinition.addEdge(state.skeleton, a, b);
    state.selectedEdgeIndex = size(state.skeleton.edges, 1);
    logMessage(services, sprintf('Connected %s to %s.', char(names(a)), char(names(b))));
end

function state = onConnectInOrder(state, ~, services)
    if locked(state) || numel(state.skeleton.pointNames) < 2
        return;
    end
    state.skeleton = video_marker.skeletonDefinition.connectInOrder(state.skeleton);
    state.selectedEdgeIndex = 0;
    logMessage(services, 'Connected adjacent keypoints in order.');
end

function state = onRemoveConnection(state, ~, services)
    idx = state.selectedEdgeIndex;
    if locked(state) || idx < 1 || idx > size(state.skeleton.edges, 1)
        return;
    end
    state.skeleton = video_marker.skeletonDefinition.removeEdge(state.skeleton, idx);
    state.selectedEdgeIndex = min(idx, size(state.skeleton.edges, 1));
    logMessage(services, sprintf('Removed connection %d.', idx));
end

function row = selectedRow(indices)
    row = 0;
    if ~isempty(indices)
        row = round(double(indices(1, 1)));
    end
end

function tf = locked(state)
    tf = state.videoInfo.frameCount > 0;
end

function logMessage(services, message)
    labkit.ui.control.appendLog(services.ui, 'appLog', message);
    services.debug.append(message);
end

function reportError(services, titleText, exception)
    services.debug.reportException('videoMarker', titleText, exception);
    labkit.ui.runtime.showAlert(services.figure, exception.message, titleText);
end
