classdef interaction
    %INTERACTION Test-only pointer math for shell-level structural tests.

    methods (Static)
        function didZoom = zoomAtPoint(ax, point, scrollCount, varargin)
            didZoom = point(1) >= min(ax.XLim) && point(1) <= max(ax.XLim) && ...
                point(2) >= min(ax.YLim) && point(2) <= max(ax.YLim);
            if ~didZoom
                return;
            end
            axesMode = "xy";
            if contains(lower(string(ax.XLabel.String)), "time")
                axesMode = "x";
            end
            for k = 1:2:numel(varargin)
                if string(varargin{k}) == "Axes"
                    axesMode = string(varargin{k + 1});
                end
            end
            factor = 1.2 .^ double(scrollCount);
            if contains(axesMode, "x")
                ax.XLim = testui.interaction.zoomLimits( ...
                    ax.XLim, point(1), factor, ax.XScale);
            end
            if contains(axesMode, "y")
                ax.YLim = testui.interaction.zoomLimits( ...
                    ax.YLim, point(2), factor, ax.YScale);
            end
            images = findobj(ax, 'Type', 'image');
            if ~isempty(images)
                data = images(1).CData;
                ax.XLim = testui.interaction.clamp(ax.XLim, ...
                    [0.5 size(data, 2) + 0.5]);
                ax.YLim = testui.interaction.clamp(ax.YLim, ...
                    [0.5 size(data, 1) + 0.5]);
            end
        end
    end

    methods (Static, Access = private)
        function limits = zoomLimits(limits, anchor, factor, scale)
            if string(scale) == "log"
                limits = log10(limits);
                anchor = log10(anchor);
                limits = anchor + (limits - anchor) .* factor;
                limits = 10 .^ limits;
            else
                limits = anchor + (limits - anchor) .* factor;
            end
        end

        function limits = clamp(limits, bounds)
            span = diff(limits);
            if limits(1) < bounds(1)
                limits = limits + bounds(1) - limits(1);
            end
            if limits(2) > bounds(2)
                limits = limits - limits(2) + bounds(2);
            end
            if span >= diff(bounds)
                limits = bounds;
            end
        end
    end
end
