function renderer = styleAwareRenderer(draw)
% Retain the last successful geometry for this plot area's live style controls.
lastAxes = struct();
lastGeometry = [];
lastStyle = [];
traces = gobjects(0);
renderer = @render;
    function render(axesById, model)
        style = [model.options.lineWidth, model.options.markerSize];
        geometry = model;
        geometry.options = rmfield(model.options, ["lineWidth","markerSize"]);
        if ~isequal(style,lastStyle) && isequal(axesById,lastAxes) && ...
                ~isempty(traces) && all(isgraphics(traces)) && isequaln(geometry,lastGeometry)
            set(traces,'LineWidth',style(1),'MarkerSize',style(2));
        else
            traces = gobjects(0);
            draw(axesById,model);
            targets = struct2cell(axesById);
            byAxis = cell(numel(targets),1);
            for k = 1:numel(targets)
                % Group error extents are hidden helpers and keep their native style.
                curves = findobj(targets{k}.Children,'-depth',0,'Type','line','-or','Type','errorbar');
                byAxis{k} = curves(:);
            end
            traces = vertcat(byAxis{:});
            lastGeometry = geometry;
            lastAxes = axesById;
        end
        lastStyle = style;
    end
end
