% App-owned DIC postprocess overlay layout helper. Expected caller:
% labkit_DICPostprocess_app. Inputs are the shell UI struct, axes titles, and
% whether plot-control panels are needed. Output is the UI struct with
% top/bottom axes and panel fields. Side effects are limited to creating axes
% and optional panels on the shell right grid.
function ui = createRightAxesPair(ui, topTitle, bottomTitle, showControls)
%CREATERIGHTAXESPAIR Create DIC postprocess overlay axes.

    if showControls
        ui.topControlsPanel = uipanel(ui.rightGrid, 'Title', topTitle);
        ui.topControlsPanel.Layout.Row = 1;
        ui.topAxes = createOneAxes(ui.rightGrid, 2, topTitle);

        ui.bottomControlsPanel = uipanel(ui.rightGrid, 'Title', bottomTitle);
        ui.bottomControlsPanel.Layout.Row = 3;
        ui.bottomAxes = createOneAxes(ui.rightGrid, 4, bottomTitle);
    else
        ui.topControlsPanel = [];
        ui.bottomControlsPanel = [];
        ui.topAxes = createOneAxes(ui.rightGrid, 1, topTitle);
        ui.bottomAxes = createOneAxes(ui.rightGrid, 2, bottomTitle);
    end
end

function ax = createOneAxes(parent, row, titleText)
    ax = uiaxes(parent);
    ax.Layout.Row = row;
    title(ax, titleText);
    labkit.ui.view.draw(ax, 'popout');
    disableAxesInteractivity(ax);
end

function disableAxesInteractivity(ax)
    try
        disableDefaultInteractivity(ax);
    catch
    end
    try
        ax.Interactions = [];
    catch
    end
    try
        ax.Toolbar.Visible = 'off';
    catch
    end
end
