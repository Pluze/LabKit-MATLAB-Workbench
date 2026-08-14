classdef Mark10LivePlotsSpec < matlab.unittest.TestCase
    %MARK10LIVEPLOTSSPEC Specify force/travel renderer output.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function drawsOfficialTimeAndForceTravelViewsWithoutRebuildingLines(testCase)
            figureHandle = figure("Visible", "off");
            cleanup = onCleanup(@() close(figureHandle));
            axesById = struct("timeSeries", axes(figureHandle), ...
                "forceTravel", axes(figureHandle));
            model = struct("time_s", [0; 1], "force_N", [1; 2], ...
                "travel_mm", [3; 4], "fitViewport", true, ...
                "limits", testLimits());

            mark10_monitor.livePlots.draw(axesById, model);
            timeLines = findobj(axesById.timeSeries, "Type", "line");
            forceTravelLine = findobj(axesById.forceTravel, ...
                "Type", "line", "Tag", "mark10ForceTravel");
            stationaryPoints = findobj(axesById.forceTravel, ...
                "Type", "line", "Tag", "mark10ForceTravelStationaryPoints");

            testCase.verifyNumElements(timeLines, 2);
            testCase.verifyNumElements(forceTravelLine, 1);
            testCase.verifyNumElements(stationaryPoints, 1);
            testCase.verifyEqual(forceTravelLine.XData, [3, 4]);
            testCase.verifyEqual(forceTravelLine.YData, [1, 2]);
            testCase.verifyEqual(string({timeLines.HitTest}), ...
                ["off", "off"]);
            testCase.verifyEqual(string(forceTravelLine.HitTest), "off");
            testCase.verifyEqual(string(forceTravelLine.PickableParts), "none");
            testCase.verifyEqual(string(axesById.timeSeries.ClippingStyle), ...
                "rectangle");
            testCase.verifyEqual(string(axesById.forceTravel.ClippingStyle), ...
                "rectangle");
            timeInteractionTypes = string(arrayfun(@class, ...
                axesById.timeSeries.Interactions, "UniformOutput", false));
            curveInteractionTypes = string(arrayfun(@class, ...
                axesById.forceTravel.Interactions, "UniformOutput", false));
            testCase.verifyTrue(any(contains( ...
                timeInteractionTypes, "PanInteraction", IgnoreCase=true)));
            testCase.verifyTrue(any(contains( ...
                curveInteractionTypes, "PanInteraction", IgnoreCase=true)));
            testCase.verifyEqual(string(axesById.timeSeries.XLimMode), ...
                "manual");
            testCase.verifyEqual(string(axesById.forceTravel.XLimMode), ...
                "manual");

            originalLines = sort([timeLines; forceTravelLine; stationaryPoints]);
            changed = struct("time_s", [0; 2], "force_N", [2; 4], ...
                "travel_mm", [6; 8], "fitViewport", false, ...
                "limits", testLimits());
            axesById.timeSeries.XLim = [-1, 1];
            axesById.forceTravel.XLim = [2, 5];
            mark10_monitor.livePlots.draw(axesById, changed);

            currentLines = sort([findobj(axesById.timeSeries, "Type", "line"); ...
                findobj(axesById.forceTravel, "Type", "line")]);
            testCase.verifyEqual(currentLines, originalLines);
            testCase.verifyEqual(forceTravelLine.XData, [6, 8]);
            testCase.verifyEqual(forceTravelLine.YData, [2, 4]);
            testCase.verifyEqual(axesById.timeSeries.XLim, [-1, 1]);
            testCase.verifyEqual(axesById.forceTravel.XLim, [2, 5]);
            clear cleanup
        end

        function disconnectsEqualTravelJumpsWithoutDroppingTheirSamples(testCase)
            figureHandle = figure("Visible", "off");
            cleanup = onCleanup(@() close(figureHandle));
            axesById = struct("timeSeries", axes(figureHandle), ...
                "forceTravel", axes(figureHandle));
            model = struct("time_s", (0:3).', ...
                "force_N", [0; 1; 0; 2], ...
                "travel_mm", [0; 1; 1; 2], "fitViewport", true, ...
                "limits", testLimits());

            mark10_monitor.livePlots.draw(axesById, model);

            curve = findobj(axesById.forceTravel, ...
                "Tag", "mark10ForceTravel");
            points = findobj(axesById.forceTravel, ...
                "Tag", "mark10ForceTravelStationaryPoints");
            testCase.verifyEqual(curve.XData, [0, 1, NaN, 1, 2]);
            testCase.verifyEqual(curve.YData, [0, 1, NaN, 0, 2]);
            testCase.verifyEqual(points.XData, [1, 1]);
            testCase.verifyEqual(points.YData, [1, 0]);
            clear cleanup
        end

        function expandsBufferedLimitsOnlyAfterDataEscapes(testCase)
            acquisition = struct("rate", "50 Hz", "actualRate_Hz", 0, ...
                "plotTime_s", [0; 4], "plotForce_N", [0; 0.8], ...
                "plotTravel_mm", [0; 8]);
            state = struct("session", struct("acquisition", acquisition, ...
                "cache", struct("plotViewRevision", 0, ...
                "plotLimits", mark10_monitor.livePlots.defaultLimits(50))));

            state = mark10_monitor.livePlots.updateLimits(state, false);
            testCase.verifyEqual(state.session.cache.plotViewRevision, 0);

            state.session.acquisition.plotTime_s(end + 1) = 6;
            state.session.acquisition.plotForce_N(end + 1) = 1.1;
            state.session.acquisition.plotTravel_mm(end + 1) = 11;
            state = mark10_monitor.livePlots.updateLimits(state, false);

            testCase.verifyEqual(state.session.cache.plotViewRevision, 1);
            testCase.verifyEqual(state.session.cache.plotLimits.time_s, [0, 11]);
            testCase.verifyEqual(state.session.cache.plotLimits.force_N, [-1, 2.2], ...
                "AbsTol", eps(2.2));
            testCase.verifyEqual(state.session.cache.plotLimits.travel_mm, [-10, 22]);
            unchanged = mark10_monitor.livePlots.updateLimits(state, false);
            testCase.verifyEqual(unchanged.session.cache.plotViewRevision, 1);
        end
    end
end

function limits = testLimits()
limits = struct("time_s", [-1, 3], "force_N", [-2, 5], ...
    "travel_mm", [-3, 9]);
end
