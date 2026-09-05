classdef LegendEditingSpec < matlab.unittest.TestCase
    % Regression oracle: explicit label/series order and immutable source data.
    % Rebuilding from the source legend after a style change must fail these checks.
    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function nativeAndPortableExportsRetainEditedRows(testCase)
            source = figure(Visible="off");
            cleanup = onCleanup(@() delete(source));
            ax = axes(source);
            plot(ax, 1:3, [1 4 2], DisplayName="First");
            hold(ax, 'on');
            plot(ax, 1:3, [2 5 3], DisplayName="Second");
            plot(ax, 1:3, [3 6 4], DisplayName="Third");
            legend(ax, 'show');
            data = figure_studio.resultFiles.extractAxesData(ax);
            document = figure_studio.figureDocument.create(data);
            rows = figure_studio.legendEditing.rows(document, "panel-1");
            rows(1).label = "_Control";
            rows(2).enabled = false;
            rows(3).label = "Treatment";
            rows = rows([3 1 2]);
            document = figure_studio.legendEditing.replaceRows(document, "panel-1", rows);
            style = figure_studio.styleLibrary.styleForPreset("LabKit figure");
            style.legendVisible = "On";
            for native = [true false]
                nativeAxes = [];
                if native, nativeAxes = ax; end
                [output, target] = figure_studio.resultFiles.createStyledFigure( ...
                    figure_studio.figureDocument.toPlotData(document), style, nativeAxes, document);
                outputCleanup = onCleanup(@() delete(output));
                testCase.verifyEqual(string(target.Legend.String), ["Treatment", "_Control"]);
                testCase.verifyEqual(string(target.Legend.AutoUpdate), "off");
                reopened = figure_studio.figureDocument.create( ...
                    figure_studio.resultFiles.extractAxesData(target));
                reopenedRows = figure_studio.legendEditing.rows(reopened, "panel-1");
                testCase.verifyEqual(string({reopenedRows.label}), ["Treatment", "_Control", "Second"]);
                testCase.verifyEqual([reopenedRows.enabled], [true true false]);
                testCase.verifyEqual(findobj(target, DisplayName="_Control").YData, [1 4 2]);
                testCase.verifyEqual(string(ax.Legend.String), ["First", "Second", "Third"]);
                style.legendFontSize = 16;
                figure_studio.resultFiles.applyFigureStyle(target, style);
                testCase.verifyEqual(string(target.Legend.String), ["Treatment", "_Control"]);
                testCase.verifyEqual(target.Legend.FontSize, 16);
                clear outputCleanup
            end
            clear cleanup
        end

        function emptyLegendStaysEmptyAndPanelCopiesRetainMapping(testCase)
            source = figure(Visible="off");
            cleanup = onCleanup(@() delete(source));
            ax = axes(source);
            plot(ax, 1:3, [1 3 2], DisplayName="Series");
            document = figure_studio.figureDocument.create( ...
                figure_studio.resultFiles.extractAxesData(ax));
            rows = figure_studio.legendEditing.rows(document, "panel-1");
            rows(1).label = "Renamed";
            rows(1).enabled = false;
            document = figure_studio.legendEditing.replaceRows(document, "panel-1", rows);
            style = figure_studio.styleLibrary.styleForPreset("LabKit figure");
            style.legendVisible = "On";
            [output, target] = figure_studio.resultFiles.createStyledFigure( ...
                figure_studio.figureDocument.toPlotData(document), style, ax, document);
            outputCleanup = onCleanup(@() delete(output));
            testCase.verifyEmpty(target.Legend);
            reopened = figure_studio.figureDocument.create(figure_studio.resultFiles.extractAxesData(target));
            testCase.verifyTrue(reopened.panels(1).legend.edited);
            testCase.verifyFalse(figure_studio.legendEditing.rows(reopened, "panel-1").enabled);
            figure_studio.resultFiles.applyFigureStyle(target, style);
            testCase.verifyEmpty(target.Legend);
            rows(1).enabled = true;
            document = figure_studio.legendEditing.replaceRows(document, "panel-1", rows);
            [document, ids] = figure_studio.figureDocument.duplicatePanels(document, "panel-1");
            copied = figure_studio.legendEditing.rows(document, ids(1));
            testCase.verifyEqual(copied.label, "Renamed");
            testCase.verifyTrue(copied.enabled);
            testCase.verifyNotEqual(copied.nodeId, rows.nodeId);
            clear outputCleanup cleanup
        end
    end
end
