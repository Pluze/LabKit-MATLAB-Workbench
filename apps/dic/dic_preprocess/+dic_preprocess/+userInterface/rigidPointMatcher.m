% Expected caller: DIC preprocess registration actions. Inputs are the two
% axes interaction runtimes, matching preview axes, and callback options.
% Output owns paired point editors, ordering, labels, and cleanup; caller-owned
% images and axes graphics remain unchanged until explicit matcher actions.
function matcher = rigidPointMatcher(referenceRuntime, movingRuntime, ...
        referenceAxes, movingAxes, opts)

    if nargin < 5
        opts = struct();
    end
    referenceEditor = [];
    movingEditor = [];
    referencePoints = zeros(0, 2);
    movingPoints = zeros(0, 2);
    updatingEditors = false;
    onChanged = optionValue(opts, 'onChanged', []);
    onTrace = optionValue(opts, 'onTrace', []);

    matcher = struct( ...
        'start', @start, ...
        'stop', @stop, ...
        'undoLast', @undoLast, ...
        'points', @points, ...
        'isActive', @isActive, ...
        'hasPoints', @hasPoints, ...
        'hasCompleteAlignment', @hasCompleteAlignment);

    function start(referenceImage, movingImage, referenceBackground, movingBackground)
        stop();
        referenceEditor = makeEditor(referenceRuntime, size(referenceImage), ...
            @onReferenceChanged);
        movingEditor = makeEditor(movingRuntime, size(movingImage), ...
            @onMovingChanged);
        referenceEditor.setBackground(referenceBackground);
        movingEditor.setBackground(movingBackground);
        updatingEditors = true;
        cleanup = onCleanup(@finishEditorUpdate);
        referenceEditor.start(referencePoints);
        movingEditor.start(movingPoints);
        clear cleanup
        notifyChanged();
    end

    function editor = makeEditor(runtime, imageSize, changedFcn)
        editor = labkit.ui.interaction.anchorEditor(runtime, imageSize, struct( ...
            'mode', 'points', ...
            'installScrollWheel', false, ...
            'onChanged', changedFcn, ...
            'onTrace', onTrace));
    end

    function onReferenceChanged(value, reason)
        if updatingEditors
            return;
        end
        if string(reason) == "add point" && ...
                size(value, 1) ~= size(movingPoints, 1) + 1
            restoreEditorPoints();
            notifyChanged(['Select the next reference feature only after ' ...
                'completing the current pair in the moving image.']);
            return;
        end
        referencePoints = value;
        notifyChanged();
    end

    function onMovingChanged(value, reason)
        if updatingEditors
            return;
        end
        if string(reason) == "add point" && ...
                size(value, 1) ~= size(referencePoints, 1)
            restoreEditorPoints();
            notifyChanged(['Select a feature in the reference image before ' ...
                'selecting its match in the moving image.']);
            return;
        end
        movingPoints = value;
        notifyChanged();
    end

    function undoLast()
        if isempty(referencePoints)
            return;
        end
        if size(referencePoints, 1) > size(movingPoints, 1)
            referencePoints(end, :) = [];
        else
            referencePoints(end, :) = [];
            movingPoints(end, :) = [];
        end
        restoreEditorPoints();
        notifyChanged();
    end

    function restoreEditorPoints()
        updatingEditors = true;
        cleanup = onCleanup(@finishEditorUpdate);
        if ~isempty(referenceEditor)
            referenceEditor.setPoints(referencePoints);
        end
        if ~isempty(movingEditor)
            movingEditor.setPoints(movingPoints);
        end
        clear cleanup
    end

    function finishEditorUpdate()
        updatingEditors = false;
    end

    function notifyChanged(instruction)
        drawPointLabels(referenceAxes, referencePoints);
        drawPointLabels(movingAxes, movingPoints);
        if nargin < 1
            if size(referencePoints, 1) > size(movingPoints, 1)
                instruction = 'Now select the matching feature in the moving image.';
            else
                instruction = 'Select the next feature in the reference image.';
            end
        end
        if ~isempty(onChanged)
            onChanged(referencePoints, movingPoints, instruction);
        end
    end

    function [fixedPoints, sourcePoints] = points()
        fixedPoints = referencePoints;
        sourcePoints = movingPoints;
    end

    function tf = isActive()
        tf = ~isempty(referenceEditor) && ~isempty(movingEditor);
    end

    function tf = hasPoints()
        tf = ~isempty(referencePoints);
    end

    function tf = hasCompleteAlignment()
        tf = size(referencePoints, 1) >= 2 && ...
            size(referencePoints, 1) == size(movingPoints, 1);
    end

    function stop()
        if ~isempty(referenceEditor)
            referenceEditor.delete();
        end
        if ~isempty(movingEditor)
            movingEditor.delete();
        end
        referenceEditor = [];
        movingEditor = [];
        referencePoints = zeros(0, 2);
        movingPoints = zeros(0, 2);
        delete(findobj(referenceAxes, 'Tag', 'dicControlPointLabel'));
        delete(findobj(movingAxes, 'Tag', 'dicControlPointLabel'));
    end
end

function drawPointLabels(ax, points)
    delete(findobj(ax, 'Tag', 'dicControlPointLabel'));
    for iPoint = 1:size(points, 1)
        text(ax, points(iPoint, 1) + 4, points(iPoint, 2), string(iPoint), ...
            'Color', [0 0.85 1], 'FontWeight', 'bold', ...
            'HitTest', 'off', 'PickableParts', 'none', ...
            'Tag', 'dicControlPointLabel');
    end
end

function value = optionValue(options, fieldName, fallback)
    value = fallback;
    if isstruct(options) && isfield(options, fieldName)
        value = options.(fieldName);
    end
end
