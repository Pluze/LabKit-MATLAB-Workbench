classdef Mark10LivePlotsSpec < matlab.unittest.TestCase
    %MARK10LIVEPLOTSSPEC Specify force/travel renderer output.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function drawsOfficialTimeAndForceTravelViewsWithoutRebuildingLines(testCase)
            figureHandle = figure("Visible", "off");
            cleanup = onCleanup(@() close(figureHandle));
            axesById = struct("timeSeries", axes(figureHandle), ...
                "forceTravel", axes(figureHandle));
            model = struct("time_s", [0; 1], "force_N", [1; 2], ...
                "travel_mm", [3; 4]);

            mark10_monitor.livePlots.draw(axesById, model);
            timeLines = findobj(axesById.timeSeries, "Type", "line");
            forceTravelLine = findobj(axesById.forceTravel, ...
                "Type", "line", "Tag", "mark10ForceTravel");

            testCase.verifyNumElements(timeLines, 2);
            testCase.verifyNumElements(forceTravelLine, 1);
            testCase.verifyEqual(forceTravelLine.XData, [3, 4]);
            testCase.verifyEqual(forceTravelLine.YData, [1, 2]);

            originalLines = sort([timeLines; forceTravelLine]);
            changed = struct("time_s", [0; 2], "force_N", [2; 4], ...
                "travel_mm", [6; 8]);
            mark10_monitor.livePlots.draw(axesById, changed);

            currentLines = sort([findobj(axesById.timeSeries, "Type", "line"); ...
                findobj(axesById.forceTravel, "Type", "line")]);
            testCase.verifyEqual(currentLines, originalLines);
            testCase.verifyEqual(forceTravelLine.XData, [6, 8]);
            testCase.verifyEqual(forceTravelLine.YData, [2, 4]);
            clear cleanup
        end
    end
end
