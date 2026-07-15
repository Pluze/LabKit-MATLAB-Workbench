classdef plot
    %PLOT Test-only access to framework-owned preview adapters.

    methods (Static)
        function ax = getAxes(ui, id, axisId)
            control = ui.controls.(char(string(id)));
            if nargin >= 3 && strlength(string(axisId)) > 0
                ax = control.axesById.(char(string(axisId)));
            else
                ax = control.primaryAxes;
            end
        end

        function handle = image(ui, id, data, varargin)
            options = testui.plot.options(varargin);
            axisId = testui.plot.option(options, 'axis', "");
            ax = testui.plot.getAxes(ui, id, axisId);
            oldLimits = {ax.XLim, ax.YLim};
            children = allchild(ax);
            images = children(isgraphics(children, 'image'));
            delete(children(~isgraphics(children, 'image')));
            if isempty(images)
                handle = image(ax, data);
                ax.XLim = [0.5 size(data, 2) + 0.5];
                ax.YLim = [0.5 size(data, 1) + 0.5];
                ax.YDir = 'reverse';
            else
                handle = images(1);
                handle.CData = data;
                if ~strcmp(ax.XLimMode, 'auto')
                    ax.XLim = oldLimits{1};
                    ax.YLim = oldLimits{2};
                end
            end
            titleText = string(testui.plot.option(options, 'title', ''));
            if isappdata(ui.figure, 'labkitSelectedFileContext')
                context = getappdata(ui.figure, 'labkitSelectedFileContext');
                titleText = titleText + " | " + sprintf( ...
                    'file %d/%d: %s', context.index, context.count, ...
                    char(context.name));
            end
            title(ax, titleText);
        end

        function clearPreview(ui, id, axisId)
            if nargin < 3
                axisId = "";
            end
            ax = testui.plot.getAxes(ui, id, axisId);
            delete(allchild(ax));
        end

        function reset(ui, id, titleText, resetScaleAndTicks, axisId)
            if nargin < 5
                axisId = "";
            end
            ax = testui.plot.getAxes(ui, id, axisId);
            cla(ax, 'reset');
            if resetScaleAndTicks
                ax.XScale = 'linear';
                ax.YScale = 'linear';
            end
            contextTitle = string(titleText);
            if isappdata(ui.figure, 'labkitSelectedFileContext')
                context = getappdata(ui.figure, 'labkitSelectedFileContext');
                contextTitle = contextTitle + " | " + sprintf( ...
                    'file %d/%d: %s', context.index, context.count, ...
                    char(context.name));
            end
            title(ax, contextTitle);
        end

        function uv = dataToFraction(ax, xy)
            uv = [(xy(:, 1) - ax.XLim(1)) ./ diff(ax.XLim), ...
                (xy(:, 2) - ax.YLim(1)) ./ diff(ax.YLim)];
        end

        function xy = fractionToData(ax, uv)
            xy = [ax.XLim(1) + uv(:, 1) .* diff(ax.XLim), ...
                ax.YLim(1) + uv(:, 2) .* diff(ax.YLim)];
        end

        function handles = replaceOverlay(ax, layerId, drawFcn)
            key = ['testUiOverlay_' char(string(layerId))];
            if isappdata(ax, key)
                delete(getappdata(ax, key));
            end
            handles = drawFcn(ax);
            setappdata(ax, key, handles);
        end
    end

    methods (Static, Access = private)
        function values = options(args)
            values = struct();
            for k = 1:2:numel(args)
                values.(char(string(args{k}))) = args{k + 1};
            end
        end

        function value = option(values, name, fallback)
            value = fallback;
            if isfield(values, name)
                value = values.(name);
            end
        end
    end
end
