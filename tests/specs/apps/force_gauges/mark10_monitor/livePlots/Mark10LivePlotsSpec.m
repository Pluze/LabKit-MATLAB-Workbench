classdef Mark10LivePlotsSpec < matlab.unittest.TestCase
    %MARK10LIVEPLOTSSPEC Specify force/travel renderer output.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function drawsOneLinePerPopulatedAxis(testCase)
            figureHandle = figure("Visible", "off");
            cleanup = onCleanup(@() close(figureHandle));
            axesById = struct("force", axes(figureHandle), ...
                "travel", axes(figureHandle));
            model = struct("time_s", [0; 1], "force_N", [1; 2], ...
                "travel_mm", [3; 4]);

            mark10_monitor.livePlots.draw(axesById, model);

            testCase.verifyNumElements(findobj(axesById.force, "Type", "line"), 1);
            testCase.verifyNumElements(findobj(axesById.travel, "Type", "line"), 1);
            clear cleanup
        end
    end
end
