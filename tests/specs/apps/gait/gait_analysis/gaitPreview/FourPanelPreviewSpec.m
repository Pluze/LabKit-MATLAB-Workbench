classdef FourPanelPreviewSpec < matlab.unittest.TestCase
    % FOURPANELPREVIEWSPEC Regression: gait data must remain visible in a two-by-two preview with equal-scale spatial overlays.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function provesFourPanelPreview(testCase)
            pose = testfixtures.syntheticGaitPose();
            options = gait_analysis.analysisRun.defaultOptions();
            options.smoothWindow = 1;
            options.detectionProminence = 2;
            options.minLiftOffIntervalSeconds = 0.1;
            options.minStepLength = 2;
            result = gait_analysis.analysisRun.computeGait(pose, options);
            model = struct( ...
                "pose", pose, "result", result, "selectedStep", 1);
            figureValue = figure(Visible="off");
            cleanup = onCleanup(@() delete(figureValue));
            layout = tiledlayout(figureValue, 2, 2);
            axesById = struct( ...
                "skeleton", nexttile(layout), ...
                "angles", nexttile(layout), ...
                "segments", nexttile(layout), ...
                "overview", nexttile(layout));

            gait_analysis.gaitPreview.draw(axesById, model);

            ids = string(fieldnames(axesById));
            for k = 1:numel(ids)
                verifyVisibleLineData( ...
                    testCase, axesById.(char(ids(k))));
            end
            verifyEqualDataUnits(testCase, axesById.skeleton);
            verifyEqualDataUnits(testCase, axesById.overview);
            overviewPoint = findobj(axesById.overview, ...
                "Type", "line", "DisplayName", pose.pointNames(1));
            testCase.verifyNumElements(overviewPoint, 1);
            testCase.verifyNumElements( ...
                overviewPoint.XData, size(pose.coords, 1));
            legends = findobj(figureValue, "Type", "legend");
            labelParts = arrayfun(@(item) ...
                string(item.String(:)), legends, UniformOutput=false);
            labels = vertcat(labelParts{:});
            testCase.verifyFalse(any(startsWith(labels, "data")));
            clear cleanup
        end
    end
end

function verifyVisibleLineData(testCase, ax)
lines = findobj(ax, "Type", "line");
x = cell2mat(arrayfun(@(line) ...
    double(line.XData(:)), lines, UniformOutput=false));
y = cell2mat(arrayfun(@(line) ...
    double(line.YData(:)), lines, UniformOutput=false));
x = x(isfinite(x));
y = y(isfinite(y));
testCase.verifyNotEmpty(x);
testCase.verifyNotEmpty(y);
testCase.verifyLessThanOrEqual(min(x), ax.XLim(2));
testCase.verifyGreaterThanOrEqual(max(x), ax.XLim(1));
testCase.verifyLessThanOrEqual(min(y), ax.YLim(2));
testCase.verifyGreaterThanOrEqual(max(y), ax.YLim(1));
end

function verifyEqualDataUnits(testCase, ax)
testCase.verifyEqual(string(ax.DataAspectRatioMode), "manual");
testCase.verifyEqual(ax.DataAspectRatio(1), ...
    ax.DataAspectRatio(2), "RelTol", 1e-10);
end
