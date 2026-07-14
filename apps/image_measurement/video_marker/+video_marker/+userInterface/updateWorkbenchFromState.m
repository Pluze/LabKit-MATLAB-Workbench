% App-owned render hook for Video Marker. Expected caller is LabKit runtime
% after action dispatch. Skeleton setup controls are state-driven; live video
% reader and point-editor rendering remains in definitionActions.
function updateWorkbenchFromState(state, ui, ~)
    renderSkeletonSetup(state, ui);
end

function renderSkeletonSetup(state, ui)
    names = state.skeleton.pointNames;
    edges = state.skeleton.edges;
    locked = state.videoInfo.frameCount > 0;
    pointCount = numel(names);

    labkit.ui.control.setValue(ui, 'keypointTable', ...
        [num2cell((1:pointCount).'), cellstr(names)]);
    labkit.ui.control.setValue(ui, 'connectionTable', edgeTable(names, edges));
    refreshConnectionChoices(ui, names);

    editable = ~locked;
    labkit.ui.control.setEnabled(ui, 'skeletonPreset', editable);
    labkit.ui.control.setEnabled(ui, 'useSkeletonPreset', editable);
    labkit.ui.control.setEnabled(ui, 'keypointTable', editable);
    labkit.ui.control.setEnabled(ui, 'connectionTable', editable);
    labkit.ui.control.setEnabled(ui, 'addKeypoint', editable);
    labkit.ui.control.setEnabled(ui, 'removeKeypoint', editable && ...
        validIndex(state.selectedPointIndex, pointCount));
    labkit.ui.control.setEnabled(ui, 'moveKeypointUp', editable && ...
        state.selectedPointIndex > 1);
    labkit.ui.control.setEnabled(ui, 'moveKeypointDown', editable && ...
        state.selectedPointIndex >= 1 && state.selectedPointIndex < pointCount);
    labkit.ui.control.setEnabled(ui, 'connectionFrom', editable && pointCount >= 2);
    labkit.ui.control.setEnabled(ui, 'connectionTo', editable && pointCount >= 2);
    labkit.ui.control.setEnabled(ui, 'addConnection', editable && pointCount >= 2);
    labkit.ui.control.setEnabled(ui, 'connectInOrder', editable && pointCount >= 2);
    labkit.ui.control.setEnabled(ui, 'removeConnection', editable && ...
        validIndex(state.selectedEdgeIndex, size(edges, 1)));
    labkit.ui.control.setEnabled(ui, 'videoFile', true);
    labkit.ui.control.setValue(ui, 'skeletonStatus', setupStatus(locked, pointCount));
end

function refreshConnectionChoices(ui, names)
    if numel(names) < 2
        labkit.ui.control.setItems(ui, 'connectionFrom', {'Add keypoints first'});
        labkit.ui.control.setItems(ui, 'connectionTo', {'Add keypoints first'});
        return;
    end
    from = validChoice(labkit.ui.control.getValue(ui, 'connectionFrom'), names, names(1));
    toCandidates = names(names ~= from);
    to = validChoice(labkit.ui.control.getValue(ui, 'connectionTo'), ...
        toCandidates, toCandidates(1));
    fromCandidates = names(names ~= to);
    from = validChoice(from, fromCandidates, fromCandidates(1));
    labkit.ui.control.setItems(ui, 'connectionFrom', cellstr(fromCandidates));
    labkit.ui.control.setValue(ui, 'connectionFrom', char(from));
    labkit.ui.control.setItems(ui, 'connectionTo', cellstr(names(names ~= from)));
    labkit.ui.control.setValue(ui, 'connectionTo', char(to));
end

function value = validChoice(candidate, choices, fallback)
    value = string(candidate);
    if ~any(choices == value)
        value = fallback;
    end
end

function data = edgeTable(names, edges)
    data = cell(size(edges, 1), 2);
    for k = 1:size(edges, 1)
        data(k, :) = cellstr(names(edges(k, :))).';
    end
end

function tf = validIndex(index, count)
    tf = isfinite(index) && index >= 1 && index <= count;
end

function text = setupStatus(locked, pointCount)
    if locked
        text = sprintf('Skeleton locked for this video: %d keypoint(s).', pointCount);
    elseif pointCount == 0
        text = 'Define keypoints to start new, or open a video to recover autosave.';
    else
        text = sprintf('Ready to open a video: %d keypoint(s).', pointCount);
    end
end
