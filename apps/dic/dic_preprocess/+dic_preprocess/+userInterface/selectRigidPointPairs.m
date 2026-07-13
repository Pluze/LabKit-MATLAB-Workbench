% Expected caller: DIC preprocess manual-alignment action. Inputs are moving
% and fixed images. Outputs are matching N-by-2 [x y] point arrays. Side
% effects: opens a modal point-pair editor until the user accepts or cancels.

function [movingPoints, fixedPoints] = selectRigidPointPairs(movingImage, fixedImage)
%SELECTRIGIDPOINTPAIRS Select draggable matching points without toolboxes.

    movingPoints = zeros(0, 2);
    fixedPoints = zeros(0, 2);
    pendingMoving = [];
    accepted = false;
    dragSide = "";
    dragIndex = [];

    fig = uifigure('Name', 'DIC Manual Alignment', ...
        'Position', [100 100 1120 680], ...
        'CloseRequestFcn', @cancelSelection);
    cleanup = onCleanup(@() closeIfValid(fig));
    root = uigridlayout(fig, [3 2], ...
        'RowHeight', {34, '1x', 42}, ...
        'ColumnWidth', {'1x', '1x'}, ...
        'Padding', [10 10 10 10]);
    status = uilabel(root, ...
        'Text', 'Click a point in the moving image.', ...
        'HorizontalAlignment', 'center', ...
        'FontWeight', 'bold');
    status.Layout.Row = 1;
    status.Layout.Column = [1 2];
    movingAxes = uiaxes(root);
    movingAxes.Layout.Row = 2;
    movingAxes.Layout.Column = 1;
    fixedAxes = uiaxes(root);
    fixedAxes.Layout.Row = 2;
    fixedAxes.Layout.Column = 2;
    movingBackground = drawImage(movingAxes, movingImage, 'Moving image');
    fixedBackground = drawImage(fixedAxes, fixedImage, 'Fixed image');

    buttonGrid = uigridlayout(root, [1 4], ...
        'ColumnWidth', {'1x', 110, 110, 110}, ...
        'Padding', [0 0 0 0]);
    buttonGrid.Layout.Row = 3;
    buttonGrid.Layout.Column = [1 2];
    countLabel = uilabel(buttonGrid, 'Text', 'Point pairs: 0');
    undoButton = uibutton(buttonGrid, 'Text', 'Undo last', ...
        'Enable', 'off', 'ButtonPushedFcn', @undoLast);
    cancelButton = uibutton(buttonGrid, 'Text', 'Cancel', ...
        'ButtonPushedFcn', @cancelSelection);
    acceptButton = uibutton(buttonGrid, 'Text', 'Accept pairs', ...
        'Enable', 'off', 'ButtonPushedFcn', @acceptSelection);

    movingRuntime = labkit.ui.interaction.runtime(movingAxes, struct('figure', fig));
    fixedRuntime = labkit.ui.interaction.runtime(fixedAxes, struct('figure', fig));
    movingSession = movingRuntime.createSession(struct( ...
        'name', 'dicMovingControlPoints', ...
        'onPointerDown', @(src, event) onPointerDown("moving", src, event), ...
        'installScrollWheel', false));
    fixedSession = fixedRuntime.createSession(struct( ...
        'name', 'dicFixedControlPoints', ...
        'onPointerDown', @(src, event) onPointerDown("fixed", src, event), ...
        'installScrollWheel', false));
    movingSession.setBackground(movingBackground);
    fixedSession.setBackground(fixedBackground);
    movingSession.activate();
    fixedSession.activate();
    redrawPoints();

    uiwait(fig);
    if ~accepted
        movingPoints = zeros(0, 2);
        fixedPoints = zeros(0, 2);
    end
    clear cleanup

    function onPointerDown(side, source, ~)
        if isgraphics(source) && isprop(source, 'UserData') && ...
                isstruct(source.UserData) && isfield(source.UserData, 'pointIndex')
            dragSide = side;
            dragIndex = source.UserData.pointIndex;
            activeSession = sessionForSide(side);
            activeSession.captureDrag(@onDrag, @onDragReleased);
            return;
        end

        point = currentPoint(side);
        if side == "moving" && isempty(pendingMoving)
            pendingMoving = point;
            status.Text = 'Click the matching point in the fixed image.';
        elseif side == "fixed" && ~isempty(pendingMoving)
            movingPoints(end + 1, :) = pendingMoving;
            fixedPoints(end + 1, :) = point;
            pendingMoving = [];
            status.Text = 'Pair added. Click another point in the moving image.';
        else
            status.Text = char("Next expected click: " + expectedSide() + " image.");
        end
        redrawPoints();
    end

    function onDrag(~, ~)
        if isempty(dragIndex)
            return;
        end
        point = currentPoint(dragSide);
        if dragIndex == 0
            pendingMoving = point;
        elseif dragSide == "moving"
            movingPoints(dragIndex, :) = point;
        else
            fixedPoints(dragIndex, :) = point;
        end
        redrawPoints();
    end

    function onDragReleased(~, ~)
        onDrag([], []);
        dragSide = "";
        dragIndex = [];
    end

    function undoLast(~, ~)
        if ~isempty(pendingMoving)
            pendingMoving = [];
        elseif ~isempty(movingPoints)
            movingPoints(end, :) = [];
            fixedPoints(end, :) = [];
        end
        status.Text = 'Click a point in the moving image.';
        redrawPoints();
    end

    function acceptSelection(~, ~)
        if size(movingPoints, 1) < 2
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

    function redrawPoints()
        movingGraphics = drawPointSet(movingAxes, movingPoints, "moving");
        if ~isempty(pendingMoving)
            pendingGraphic = drawPoint(movingAxes, pendingMoving, ...
                size(movingPoints, 1) + 1, "moving", 0, [1 0.85 0]);
            movingGraphics = [movingGraphics; pendingGraphic];
        end
        fixedGraphics = drawPointSet(fixedAxes, fixedPoints, "fixed");
        movingSession.setGraphics(movingGraphics);
        fixedSession.setGraphics(fixedGraphics);
        movingSession.refresh();
        fixedSession.refresh();
        countLabel.Text = sprintf('Point pairs: %d', size(movingPoints, 1));
        undoButton.Enable = enabledText(~isempty(pendingMoving) || ~isempty(movingPoints));
        acceptButton.Enable = enabledText(size(movingPoints, 1) >= 2);
    end

    function point = currentPoint(side)
        if side == "moving"
            ax = movingAxes;
            imageSize = size(movingImage);
        else
            ax = fixedAxes;
            imageSize = size(fixedImage);
        end
        value = double(ax.CurrentPoint);
        point = value(1, 1:2);
        point(1) = min(max(point(1), 1), imageSize(2));
        point(2) = min(max(point(2), 1), imageSize(1));
    end

    function session = sessionForSide(side)
        if side == "moving"
            session = movingSession;
        else
            session = fixedSession;
        end
    end

    function side = expectedSide()
        side = "moving";
        if ~isempty(pendingMoving)
            side = "fixed";
        end
    end
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

function graphics = drawPointSet(ax, points, side)
    delete(findobj(ax, 'Tag', 'dicControlPoint'));
    graphics = gobjects(0);
    for iPoint = 1:size(points, 1)
        graphics(end + 1, 1) = drawPoint(ax, points(iPoint, :), ...
            iPoint, side, iPoint, [0 0.85 1]);
    end
end

function graphic = drawPoint(ax, point, labelIndex, side, pointIndex, color)
    graphic = line(ax, point(1), point(2), ...
        'LineStyle', 'none', 'Marker', '+', 'MarkerSize', 12, ...
        'LineWidth', 2, 'Color', color, 'Tag', 'dicControlPoint', ...
        'UserData', struct('side', side, 'pointIndex', pointIndex));
    text(ax, point(1) + 4, point(2), string(labelIndex), ...
        'Color', color, 'FontWeight', 'bold', ...
        'HitTest', 'off', 'PickableParts', 'none', ...
        'Tag', 'dicControlPoint');
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
