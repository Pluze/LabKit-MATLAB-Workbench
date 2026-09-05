classdef OverviewPlotSpec < matlab.unittest.TestCase
    %OVERVIEWPLOTSPEC Preserve source grids, units, and gaps in EIS plots.
    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function preservesIndependentGridsAndInvalidGaps(testCase)
            fig = figure("Visible", "off");
            cleanup = onCleanup(@() delete(fig));
            axesById = struct("nyquist", subplot(1,3,1,"Parent",fig), ...
                "magnitude", subplot(1,3,2,"Parent",fig), ...
                "phase", subplot(1,3,3,"Parent",fig));
            first = struct("name", "First", "freq_Hz", [100 0 10], ...
                "Zreal_ohm", [1000 2000 3000], ...
                "negZimag_ohm", [100 200 300], ...
                "Zmod_ohm", [1000 2000 3000], "Zphz_deg", [-10 -20 -30]);
            second = struct("name", "Second", "freq_Hz", [80 20], ...
                "Zreal_ohm", [4000 5000], "negZimag_ohm", [400 500], ...
                "Zmod_ohm", [4000 NaN], "Zphz_deg", [-40 -50]);
            project = eis.initialData();
            units = eis.impedanceDisplay.catalog();
            project.parameters.impedanceUnit = units.choices(3);
            model = struct("items", [first second], ...
                "options", project.parameters, "hasItems", true);
            eis.overlayPlot.drawOverview(axesById, model);
            % Independent oracle: explicit source coordinates and unit ratio.
            % Joining a gap or resampling onto a shared grid violates it.
            lines = flipud(findall(axesById.magnitude, "Type", "line"));
            testCase.verifyEqual(lines(1).XData, [100 NaN 10]);
            testCase.verifyEqual(lines(1).YData, [1 NaN 3]);
            testCase.verifyEqual(lines(2).XData, [80 NaN]);
            testCase.verifyEqual(axesById.magnitude.XScale, 'log');
            testCase.verifyEqual(axesById.magnitude.YScale, 'log');
            phase = flipud(findall(axesById.phase, "Type", "line"));
            testCase.verifyEqual(phase(2).XData, [80 20]);
            testCase.verifyEqual(phase(2).YData, [-40 -50]);
            testCase.verifyEqual(axesById.phase.YScale, 'linear');
            testCase.verifyEqual(axesById.nyquist.DataAspectRatio(1:2), [1 1]);
            clear cleanup
        end
    end
end
