classdef OverviewPlotSpec < matlab.unittest.TestCase
    %OVERVIEWPLOTSPEC Preserve source grids, units, and gaps in EIS plots.
    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function drawsGroupErrorBarsAndFitsTheirExtents(testCase)
            % Oracle: [1,3] kOhm has mean 2 and SD sqrt(2) in both directions.
            fig = figure("Visible", "off");
            cleanup = onCleanup(@() delete(fig));
            ax = axes(fig);
            a = struct("freq_Hz", [100;10], "Zreal_ohm", [1000;2000], ...
                "negZimag_ohm", [1000;2000]);
            b = struct("freq_Hz", [100;10], "Zreal_ohm", [3000;4000], ...
                "negZimag_ohm", [3000;4000]);
            group = struct("name", "Sample A", "members", [a b]);
            project = eis.initialData();
            eis.overlayPlot.plotOverlay(ax, group, project.parameters);
            bars = findall(ax, "Type", "errorbar");
            testCase.verifyEqual(bars.XData, [2 3]);
            testCase.verifyEqual(bars.YPositiveDelta, [sqrt(2) sqrt(2)], AbsTol=1e-12);
            testCase.verifyEqual(bars.XNegativeDelta, [sqrt(2) sqrt(2)], AbsTol=1e-12);
            testCase.verifyLessThan(ax.XLim(1), 2-sqrt(2));
            testCase.verifyGreaterThan(ax.YLim(2), 3+sqrt(2));
            group.members(1).Zreal_ohm = [-3000;2000];
            project.parameters.logX = true;
            eis.overlayPlot.plotOverlay(ax, group, project.parameters);
            bars = findall(ax, "Type", "errorbar");
            testCase.verifyTrue(isnan(bars.XData(1)));
            testCase.verifyEqual(ax.XScale, 'log');
            clear cleanup
        end

        function recommendsResolvedArcButKeepsAmbiguousSpectraFull(testCase)
            % Oracle: an explicit arc descends to its 10 Hz valley before a
            % dominant tail. Monotonic and tail-free curves supply no evidence.
            f = logspace(5,-1,19).';
            y = [1 2 4 8 12 16 18 16 12 8 5 3 2 3 6 20 60 80 100].';
            item = struct("freq_Hz", f, "negZimag_ohm", y, ...
                "Zreal_ohm", (1:19).');
            [lower, supported] = eis.overlayPlot.recommendFrequency(item, -1);
            testCase.verifyEqual(lower, 1, AbsTol=1e-12);
            testCase.verifyEqual(supported, 1);
            scaled = item;
            scaled.negZimag_ohm = y * 1e6;
            scaled.Zreal_ohm = scaled.Zreal_ohm * 1e6;
            testCase.verifyEqual(eis.overlayPlot.recommendFrequency(scaled, -1), lower);
            reverse = item;
            reverse.freq_Hz = flipud(f);
            reverse.negZimag_ohm = flipud(y);
            reverse.Zreal_ohm = flipud(item.Zreal_ohm);
            testCase.verifyEqual(eis.overlayPlot.recommendFrequency(reverse, -1), lower);
            shifted = item; shifted.freq_Hz = f / 10;
            testCase.verifyEqual(eis.overlayPlot.recommendFrequency([item shifted], -2), 0, AbsTol=1e-12);
            monotonic = item; monotonic.negZimag_ohm = (1:19).';
            [full, count] = eis.overlayPlot.recommendFrequency(monotonic, -1);
            testCase.verifyEqual(full, -1); testCase.verifyEqual(count, 0);
            noTail = item; noTail.negZimag_ohm(14:end) = 2;
            testCase.verifyEqual(eis.overlayPlot.recommendFrequency(noTail, -1), -1);
            testCase.verifyEqual(eis.overlayPlot.recommendFrequency(struct([]), 0), 0);
        end

        function frequencyWindowMasksRawAndGroupedTails(testCase)
            % Oracle: only 10 Hz remains in [1,2] log10 Hz; the 1 Hz tail
            % must not contribute coordinates or SD extents to fitted limits.
            fig = figure("Visible", "off");
            cleanup = onCleanup(@() delete(fig));
            ax = axes(fig);
            a = struct("name", "Scan", "freq_Hz", [1000;10;1], ...
                "Zreal_ohm", [1000;2000;1e8], ...
                "negZimag_ohm", [500;1000;2e8]);
            project = eis.initialData();
            options = project.parameters;
            options.frequencyLogRange = [1 2];
            eis.overlayPlot.plotOverlay(ax, a, options);
            curve = findall(ax, "Type", "line");
            testCase.verifyEqual(curve.XData, [NaN 2 NaN]);
            testCase.verifyEqual(curve.YData, [NaN 1 NaN]);
            testCase.verifyLessThan(ax.YLim(2), 10);
            b = a; b.Zreal_ohm(2) = 4000;
            group = struct("name", "Sample", "members", [a b]);
            eis.overlayPlot.plotOverlay(ax, group, options);
            bars = findall(ax, "Type", "errorbar");
            testCase.verifyEqual(bars.XData, [NaN 3 NaN]);
            testCase.verifyEqual(bars.XPositiveDelta(2), sqrt(2), AbsTol=1e-12);
            testCase.verifyLessThan(ax.XLim(2), 10);
            options.frequencyLogRange = [1.1 1.2];
            eis.overlayPlot.plotOverlay(ax, a, options);
            curve = findall(ax, "Type", "line");
            testCase.verifyTrue(all(isnan(curve.XData)));
            testCase.verifyTrue(all(isfinite([ax.XLim ax.YLim])));
            clear cleanup
        end

        function preservesIndependentGridsAndInvalidGaps(testCase)
            fig = figure("Visible", "off");
            cleanup = onCleanup(@() delete(fig));
            axesById = struct("nyquist", subplot(1,3,1,"Parent",fig), ...
                "magnitude", subplot(1,3,2,"Parent",fig), ...
                "phase", subplot(1,3,3,"Parent",fig));
            first = struct("name", "series-First", "freq_Hz", [100 0 10], ...
                "Zreal_ohm", [1000 2000 3000], ...
                "negZimag_ohm", [100 200 300], ...
                "Zmod_ohm", [1000 2000 3000], "Zphz_deg", [-10 -20 -30]);
            second = struct("name", "series-Second", "freq_Hz", [80 20], ...
                "Zreal_ohm", [4000 5000], "negZimag_ohm", [400 500], ...
                "Zmod_ohm", [4000 NaN], "Zphz_deg", [-40 -50]);
            project = eis.initialData();
            units = eis.impedanceDisplay.catalog();
            project.parameters.impedanceUnit = units.choices(3);
            model = struct("items", [first second], ...
                "options", project.parameters, "hasItems", true);
            eis.overlayPlot.drawOverview(axesById, model);
            testCase.verifyEmpty(axesById.magnitude.Legend);
            testCase.verifyEmpty(axesById.phase.Legend);
            testCase.verifyEqual(string(axesById.nyquist.Legend.String), ["First" "Second"]);
            testCase.verifyEqual(string({model.items.name}), ["series-First" "series-Second"]);
            % Independent oracle: explicit source coordinates and unit ratio.
            % Joining a gap or resampling onto a shared grid violates it.
            lines = flipud(findall(axesById.magnitude, "Type", "line"));
            testCase.verifyEqual(lines(1).XData, [100 NaN 10]);
            testCase.verifyEqual(lines(1).YData, [1 NaN 3]);
            testCase.verifyEqual(lines(2).XData, [80 NaN]);
            testCase.verifyEqual(axesById.magnitude.XScale, 'log');
            testCase.verifyEqual(axesById.magnitude.YScale, 'linear');
            phase = flipud(findall(axesById.phase, "Type", "line"));
            testCase.verifyEqual(phase(2).XData, [80 20]);
            testCase.verifyEqual(phase(2).YData, [-40 -50]);
            testCase.verifyEqual(axesById.phase.YScale, 'linear');
            testCase.verifyEqual(axesById.nyquist.DataAspectRatio(1:2), [1 1]);
            clear cleanup
        end
    end
end
