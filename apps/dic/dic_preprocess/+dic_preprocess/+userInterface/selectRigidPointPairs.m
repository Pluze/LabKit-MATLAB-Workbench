% Expected caller: DIC preprocess manual-alignment action. Inputs are moving
% and fixed images. An optional options.onReady callback receives the completed
% editor figure immediately before the modal wait. Outputs are matching N-by-2
% [x y] point arrays. Side effects: opens a modal point-pair editor until the
% user accepts or cancels.

function [movingPoints, fixedPoints] = selectRigidPointPairs( ...
        movingImage, fixedImage, options)
%SELECTRIGIDPOINTPAIRS Select draggable matching points without toolboxes.

    if nargin < 3
        options = struct();
    end

    movingPoints = zeros(0, 2);
    fixedPoints = zeros(0, 2);
    accepted = false;
    updatingEditors = false;
    editorsReady = false;

    fig = uifigure('Name', 'DIC Manual Alignment', ...
        'Position', [100 100 1120 680], ...
        'CloseRequestFcn', @cancelSelection);
    cleanup = onCleanup(@() closeIfValid(fig));
    status = uilabel(fig, ...
        'Text', ['Single-click a feature in the moving image; ' ...
        'drag any existing anchor to refine it.'], ...
        'HorizontalAlignment', 'center', ...
        'FontWeight', 'bold', ...
        'Position', [20 638 1080 28]);
    movingAxes = uiaxes(fig, 'Position', [25 100 525 525]);
    fixedAxes = uiaxes(fig, 'Position', [570 100 525 525]);
    movingBackground = drawImage(movingAxes, movingImage, 'Moving image');
    fixedBackground = drawImage(fixedAxes, fixedImage, 'Fixed image');

    countLabel = uilabel(fig, 'Text', 'Point pairs: 0', ...
        'Position', [25 35 650 30]);
    undoButton = uibutton(fig, 'Text', 'Undo last', ...
        'Position', [720 32 110 34], ...
        'Enable', 'off', 'ButtonPushedFcn', @undoLast);
    cancelButton = uibutton(fig, 'Text', 'Cancel', ...
        'Position', [845 32 110 34], ...
        'ButtonPushedFcn', @cancelSelection);
    acceptButton = uibutton(fig, 'Text', 'Accept pairs', ...
        'Position', [970 32 110 34], ...
        'Enable', 'off', 'ButtonPushedFcn', @acceptSelection);

    movingRuntime = labkit.ui.interaction.runtime(movingAxes, struct('figure', fig));
    fixedRuntime = labkit.ui.interaction.runtime(fixedAxes, struct('figure', fig));
    pointOptions = struct('mode', 'points', 'installScrollWheel', false);
    movingOptions = pointOptions;
    movingOptions.onChanged = @onMovingChanged;
    fixedOptions = pointOptions;
    fixedOptions.onChanged = @onFixedChanged;
    movingEditor = labkit.ui.interaction.anchorEditor( ...
        movingRuntime, size(movingImage), movingOptions);
    fixedEditor = labkit.ui.interaction.anchorEditor( ...
        fixedRuntime, size(fixedImage), fixedOptions);
    movingEditor.setBackground(movingBackground);
    fixedEditor.setBackground(fixedBackground);
    movingEditor.start(movingPoints);
    fixedEditor.start(fixedPoints);
    editorsReady = true;
    refreshPointDisplay();
    notifyReady(options, fig);

    uiwait(fig);
    movingEditor.delete();
    fixedEditor.delete();
    if ~accepted
        movingPoints = zeros(0, 2);
        fixedPoints = zeros(0, 2);
    end
    clear cleanup

    function onMovingChanged(points, reason)
        if ~editorsReady || updatingEditors
            return;
        end
        if string(reason) == "add point" && ...
                size(movingPoints, 1) ~= size(fixedPoints, 1)
            restoreEditorPoints(movingEditor, movingPoints);
            status.Text = 'Place the matching point in the fixed image first.';
            return;
        end
        movingPoints = points;
        if size(movingPoints, 1) > size(fixedPoints, 1)
            status.Text = 'Now single-click the matching point in the fixed image.';
        end
        refreshPointDisplay();
    end

    function onFixedChanged(points, reason)
        if ~editorsReady || updatingEditors
            return;
        end
        if string(reason) == "add point" && ...
                size(movingPoints, 1) ~= size(fixedPoints, 1) + 1
            restoreEditorPoints(fixedEditor, fixedPoints);
            status.Text = 'Start the next pair in the moving image.';
            return;
        end
        fixedPoints = points;
        if size(movingPoints, 1) == size(fixedPoints, 1)
            status.Text = ['Pair added. Single-click another moving feature, ' ...
                'or drag any anchor to refine it.'];
        end
        refreshPointDisplay();
    end

    function undoLast(~, ~)
        if size(movingPoints, 1) > size(fixedPoints, 1)
            movingPoints(end, :) = [];
        elseif ~isempty(movingPoints)
            movingPoints(end, :) = [];
            fixedPoints(end, :) = [];
        end
        updateEditorPoints();
        status.Text = ['Single-click a feature in the moving image; ' ...
            'drag any existing anchor to refine it.'];
        refreshPointDisplay();
    end

    function acceptSelection(~, ~)
        if size(movingPoints, 1) < 2 || ...
                size(movingPoints, 1) ~= size(fixedPoints, 1)
            return;
        end
        accepted = true;
        uiresume(fig);
    end

    function cancelSelection(~, ~)
        accepted = false;
        if isvalid(fig)
            uiresume(fig);
        end
    end

    function refreshPointDisplay()
        drawPointLabels(movingAxes, movingPoints);
        drawPointLabels(fixedAxes, fixedPoints);
        countLabel.Text = sprintf('Point pairs: %d', size(movingPoints, 1));
        undoButton.Enable = enabledText(~isempty(movingPoints));
        acceptButton.Enable = enabledText(size(movingPoints, 1) >= 2 && ...
            size(movingPoints, 1) == size(fixedPoints, 1));
    end

    function restoreEditorPoints(editor, points)
        updatingEditors = true;
        editor.setPoints(points);
        updatingEditors = false;
    end

    function updateEditorPoints()
        updatingEditors = true;
        movingEditor.setPoints(movingPoints);
        fixedEditor.setPoints(fixedPoints);
        updatingEditors = false;
    end
end

function notifyReady(options, fig)
    if ~isfield(options, 'onReady') || isempty(options.onReady)
        return;
    end
    if ~isa(options.onReady, 'function_handle')
        error('LabKit:DIC:InvalidPointSelectorReadyCallback', ...
            'options.onReady must be a function handle.');
    end
    options.onReady(fig);
end

function background = drawImage(ax, imageData, titleText)
    if ndims(imageData) == 2
        background = imagesc(ax, double(imageData));
        colormap(ax, gray(256));
    else
        rgb = labkit.image.ensureRgb(labkit.image.im2double(imageData));
        background = image(ax, min(max(rgb, 0), 1));
    end
    axis(ax, 'image');
    ax.YDir = 'reverse';
    ax.Title.String = titleText;
    ax.XLabel.String = 'x (px)';
    ax.YLabel.String = 'y (px)';
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

function value = enabledText(condition)
    value = 'off';
    if condition
        value = 'on';
    end
end

function closeIfValid(fig)
    if ~isempty(fig) && isvalid(fig)
        delete(fig);
    end
end
