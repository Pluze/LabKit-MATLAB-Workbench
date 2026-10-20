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

        function recommendsAnArcWithAnElevatedHighFrequencyBoundary(testCase)
            % Oracle: a 16-ohm peak is prominent above a 10-ohm boundary and
            % descends to a recorded 10 Hz valley before a dominant tail.
            % Requiring a twofold rise would incorrectly keep the full tail.
            f = logspace(5,-1,19).';
            y = [10 10 11 12 13 15 16 15 12 10 8 6 5 6 9 25 60 80 100].';
            item = struct("freq_Hz", f, "negZimag_ohm", y, ...
                "Zreal_ohm", (1:19).');
            [lower, supported] = eis.overlayPlot.recommendFrequency(item, -1);
            testCase.verifyEqual(lower, 1, AbsTol=1e-12);
            testCase.verifyEqual(supported, 1);
            shallow = item;
            shallow.negZimag_ohm(1:4) = 12;
            testCase.verifyEqual(eis.overlayPlot.recommendFrequency(shallow, -1), -1);
            noTail = item;
            noTail.negZimag_ohm(14:end) = 5;
            testCase.verifyEqual(eis.overlayPlot.recommendFrequency(noTail, -1), -1);
            sparse = item;
            sparse.freq_Hz = f(1:11);
            sparse.Zreal_ohm = item.Zreal_ohm(1:11);
            sparse.negZimag_ohm = y(1:11);
            testCase.verifyEqual(eis.overlayPlot.recommendFrequency(sparse, -1), -1);
            duplicate = item;
            duplicate.freq_Hz(2) = f(1);
            testCase.verifyEqual(eis.overlayPlot.recommendFrequency(duplicate, -1), -1);
        end

        function formatsFrequencyWithUnitsAndNoExponent(testCase)
            % Oracle: decimal SI conversion, four-digit rounding, and carry
            % across a unit boundary must remain readable in narrow captions.
            values = [0.12345 2500 1234567 999999.9 1e9 1e-6];
            expected = ["0.1235 Hz" "2.5 kHz" "1.235 MHz" "1 MHz" "1 GHz" "0.000001 Hz"];
            for k = 1:numel(values)
                testCase.verifyEqual(eis.overlayPlot.formatFrequency(values(k)), expected(k));
            end
        end

        function fillsNyquistCoordinateSpaceWithoutStretchingData(testCase)
            % Oracle: equal units require the limit-span ratio to match the
            % available pixel ratio, including a tall trace and a wide trace.
            fig = figure("Visible", "off", "Position", [0 0 900 450]);
            cleanup = onCleanup(@() delete(fig));
            ax = axes(fig);
            for xy = {[1 2 3; 0 500 1000], [0 500 1000; 1 2 3]}
                values = xy{1};
                plot(ax, values(1,:), values(2,:));
                eis.overlayPlot.fitNyquistViewport(ax);
                position = getpixelposition(ax);
                allocation = ax.Position;
                inner = ax.InnerPosition;
                position(3:4) = inner(3:4) .* position(3:4) ./ allocation(3:4);
                testCase.verifyEqual(diff(ax.XLim)/diff(ax.YLim), ...
                    position(3)/position(4), RelTol=.02);
                testCase.verifyEqual(ax.DataAspectRatio(1), ax.DataAspectRatio(2), AbsTol=1e-12);
                testCase.verifyLessThanOrEqual(ax.XLim(1), min(values(1,:)));
                testCase.verifyGreaterThanOrEqual(ax.XLim(2), max(values(1,:)));
                testCase.verifyLessThanOrEqual(ax.YLim(1), min(values(2,:)));
                testCase.verifyGreaterThanOrEqual(ax.YLim(2), max(values(2,:)));
            end
            clear cleanup
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
