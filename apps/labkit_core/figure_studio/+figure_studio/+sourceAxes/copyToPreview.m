% Copy axes graphics and display state into a Figure Studio preview axes.
% Expected caller is figure_studio.definitionActions; source graphics are not
% modified and destination axes content is reset before children are copied.
function copyToPreview(srcAx, dstAx)
    cla(dstAx, 'reset');
    dstAx.Visible = 'on';
    disableDefaultAxesToolbar(dstAx);
    copyAxesState(srcAx, dstAx);
    children = flipud(srcAx.Children(:));
    if ~isempty(children)
        copyobj(children, dstAx);
    end
    title(dstAx, string(srcAx.Title.String), 'Interpreter', 'none');
    xlabel(dstAx, string(srcAx.XLabel.String), 'Interpreter', 'none');
    ylabel(dstAx, string(srcAx.YLabel.String), 'Interpreter', 'none');
    zlabel(dstAx, string(srcAx.ZLabel.String), 'Interpreter', 'none');
    normalizePreviewAxesLayout(dstAx);
    labkit.ui.tool.enableAxesPopout(dstAx);
end

function disableDefaultAxesToolbar(ax)
    try
        ax.Toolbar.Visible = 'off';
        disableDefaultInteractivity(ax);
    catch
    end
end

function copyAxesState(srcAx, dstAx)
    props = {'XScale','YScale','ZScale','XDir','YDir','ZDir', ...
        'XLim','YLim','ZLim','CLim','View','Box','XGrid','YGrid','ZGrid', ...
        'Color','XColor','YColor','ZColor','LineWidth','FontName','FontSize'};
    for k = 1:numel(props)
        try
            dstAx.(props{k}) = srcAx.(props{k});
        catch
        end
    end
    try
        colormap(dstAx, colormap(srcAx));
    catch
    end
end

function normalizePreviewAxesLayout(ax)
    props = {'DataAspectRatioMode', 'PlotBoxAspectRatioMode'};
    for k = 1:numel(props)
        try
            ax.(props{k}) = 'auto';
        catch
        end
    end
end
