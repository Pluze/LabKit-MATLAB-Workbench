% Copy axes graphics and display state into a Figure Studio preview axes.
% Expected caller is Figure Studio direct callbacks; source graphics are not
% modified and destination axes content is reset before children are copied.
function copyToPreview(srcAx, dstAx)
    labkit.app.plot.clearAxes(dstAx);
    dstAx.Visible = 'on';
    title(dstAx, "");
    xlabel(dstAx, "");
    ylabel(dstAx, "");
    zlabel(dstAx, "");
    disableDefaultAxesToolbar(dstAx);
    copyAxesState(srcAx, dstAx);
    children = flipud(allchild(srcAx));
    children = children(:);
    labels = [srcAx.Title; srcAx.XLabel; srcAx.YLabel; srcAx.ZLabel];
    children(ismember(children, labels)) = [];
    if ~isempty(children)
        copyobj(children, dstAx);
    end
    title(dstAx, string(srcAx.Title.String), 'Interpreter', 'none');
    xlabel(dstAx, string(srcAx.XLabel.String), 'Interpreter', 'none');
    ylabel(dstAx, string(srcAx.YLabel.String), 'Interpreter', 'none');
    zlabel(dstAx, string(srcAx.ZLabel.String), 'Interpreter', 'none');
    figure_studio.sourceAxes.copyLegend(srcAx, dstAx);
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
        'XLim','YLim','ZLim','CLim','Layer','Box','XGrid','YGrid','ZGrid', ...
        'XTick','YTick','ZTick','XTickLabel','YTickLabel','ZTickLabel', ...
        'XTickLabelRotation','YTickLabelRotation','ZTickLabelRotation', ...
        'XAxisLocation','YAxisLocation','TickLength','TickLabelInterpreter', ...
        'DataAspectRatio','DataAspectRatioMode','PlotBoxAspectRatio', ...
        'PlotBoxAspectRatioMode', ...
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
