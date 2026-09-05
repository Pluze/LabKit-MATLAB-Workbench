classdef FigureStudioWorkflowSpec < matlab.unittest.TestCase
    %FIGURESTUDIOWORKFLOWSPEC Specify the bounded FIG-preview-export workflow.

    methods (TestMethodSetup)
        function keepNativeRuntimeHidden(testCase)
            previous = getenv("LABKIT_GUI_TEST_MODE");
            testCase.addTeardown(@setenv, "LABKIT_GUI_TEST_MODE", previous);
            setenv("LABKIT_GUI_TEST_MODE", "hidden");
        end
    end

    methods (Test, TestTags = {'Contract:workflow', 'Env:hidden-gui'})
        function loadsAFigureIntoTheInteractivePreviewAndExportsPng(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            sourcePath = fullfile(folder, "probe.fig");
            outputPath = fullfile(folder, "styled.png");
            svgPath = fullfile(folder, "styled.svg");
            jpgPath = fullfile(folder, "styled.jpg");
            figPath = fullfile(folder, "styled.fig");
            writeProbe(sourcePath);
            backend = struct( ...
                "chooseOutputFile", @(filters, ~) ...
                    labkit.app.dialog.Choice( ...
                    exportPathForFilter(folder, filters)), ...
                "chooseInputFile", @(~, ~) ...
                    labkit.app.dialog.Choice(fullfile(folder, "styled.mat")), ...
                "chooseOutputFolder", @(~) labkit.app.dialog.Choice(folder), ...
                "alert", @(~, ~) []);
            definition = figure_studio.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createMatlabRuntime( ...
                definition, [], backend, journal);
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();

            runtime.applyFileSelection("figFiles", sourcePath, 1);
            preview = findall(figureValue, "Tag", "preview.main");
            export = findall(figureValue, "Tag", "exportCurrent");

            testCase.verifyNotEmpty(runtime.State.session.cache.plotData);
            testCase.verifyNotEmpty(preview.Children);
            testCase.verifyEmpty(findall(preview, "Type", "image"));
            activeStyle = runtime.State.project.parameters.style;
            standard = figure_studio.styleLibrary.styleForPreset("LabKit figure");
            testCase.verifyEqual(runtime.State.project.parameters.aspectPreset, ...
                "Reference");
            testCase.verifyEqual([activeStyle.canvasWidth ...
                activeStyle.canvasHeight], [standard.canvasWidth ...
                standard.canvasHeight]);
            testCase.verifyEqual(activeStyle.tickFontSize, ...
                standard.tickFontSize);
            testCase.verifyEqual(string(export.Enable), "on");

            runtime.invokeAction("recalculateLimits");
            runtime.applyControlValue("xMin", 0);
            runtime.applyControlValue("xMax", 5);
            runtime.applyControlValue("yMin", 0);
            runtime.applyControlValue("yMax", 5);
            testCase.verifyEqual( ...
                runtime.State.session.editor.document.panels(1).axes.x.limits, ...
                [0 5]);
            testCase.verifyEqual( ...
                runtime.State.session.editor.document.panels(1).axes.y.limits, ...
                [0 5]);

            runtime.applyControlValue("figureTitle", "Publication trace");
            runtime.applyControlValue("figureSubtitle", "Synthetic evidence");
            runtime.applyControlValue("xAxisLabel", "Time (s)");
            runtime.applyControlValue("yAxisLabel", "Response");
            runtime.applyControlValue("rightYAxisLabel", "Secondary response");
            runtime.applyControlValue("axisTarget", "X");
            runtime.applyControlValue("axisScale", "linear");
            runtime.applyControlValue("axisDirection", "normal");
            runtime.applyControlValue("axisMinimum", 0);
            runtime.applyControlValue("axisMaximum", 5);
            runtime.applyControlValue("axisLocation", "bottom");
            runtime.applyControlValue("tickLocator", "Nice count");
            runtime.applyControlValue("tickCount", 6);
            runtime.applyControlValue("tickLocator", "Fixed step");
            runtime.applyControlValue("tickStep", 1);
            runtime.applyControlValue("tickFormatter", "Fixed");
            runtime.applyControlValue("tickPrecision", 2);
            runtime.applyControlValue("tickPrefix", "t=");
            runtime.applyControlValue("tickSuffix", " s");
            tickCount = numel(runtime.State.session.editor.document.panels(1).axes.x.ticks);
            runtime.invokeAction("addTick");
            testCase.verifyEqual(numel( ...
                runtime.State.session.editor.document.panels(1).axes.x.ticks), ...
                tickCount + 1);
            runtime.applyTableEdit("tickTable", ...
                labkit.app.event.TableCellEdit(RowIndex=1, ColumnIndex=2, ...
                    PreviousValue="0.00", NewValue="start"));
            testCase.verifyEqual(runtime.State.session.editor.document. ...
                panels(1).axes.x.ticks(1).label, "start");
            runtime.applyTableSelection("tickTable", [1 1]);
            runtime.invokeAction("deleteTicks");
            runtime.invokeAction("undoFigureEdit");
            runtime.invokeAction("redoFigureEdit");
            panel = runtime.State.session.editor.document.panels(1);
            testCase.verifyEqual(panel.text.title, "Publication trace");
            testCase.verifyEqual(panel.text.subtitle, "Synthetic evidence");
            testCase.verifyEqual(panel.axes.x.formatter.mode, "explicit");
            testCase.verifyEqual(panel.axes.x.formatter.precision, 2);

            runtime.applyControlValue("colorbarVisible", "On");
            runtime.applyControlValue("colorbarLabel", "Intensity");
            runtime.applyControlValue("colorbarLocation", "eastoutside");
            runtime.applyControlValue("colorMin", 0);
            runtime.applyControlValue("colorMax", 5);
            runtime.applyControlValue("colorbarTicks", "0 2.5 5");
            runtime.applyControlValue("colorbarTickLabels", "low|mid|high");
            runtime.applyControlValue("colormapName", "turbo");
            color = runtime.State.session.editor.document.panels(1).color;
            testCase.verifyTrue(color.bar.enabled);
            testCase.verifyEqual(color.bar.label, "Intensity");
            testCase.verifyEqual(color.bar.ticks, [0 2.5 5]);
            testCase.verifySize(color.colormap, [256 3]);

            runtime.applyControlValue("stylePreset", "LabKit figure");
            runtime.applyControlValue("baseFontSize", 11);
            runtime.applyControlValue("titleFontSize", 14);
            runtime.applyControlValue("labelFontSize", 12);
            runtime.applyControlValue("tickFontSize", 10);
            runtime.applyControlValue("annotationFontSize", 9);
            runtime.applyControlValue("xTickLabelAngle", "45 deg");
            runtime.applyControlValue("gridAlpha", 0.25);
            runtime.applyControlValue("gridVisible", "On");
            runtime.applyControlValue("dataLineWidth", 2);
            runtime.applyControlValue("uncertaintyLineWidth", 1.5);
            runtime.applyControlValue("boundaryLineWidth", 1.2);
            runtime.applyControlValue("referenceLineWidth", 1.1);
            runtime.applyControlValue("axesLineWidth", 1.3);
            runtime.applyControlValue("legendVisible", "On");
            runtime.applyControlValue("legendLocation", "northeast");
            runtime.applyControlValue("legendFontSize", 9);
            runtime.applyControlValue("legendNumColumns", 1);
            runtime.applyControlValue("legendBox", "Off");
            style = runtime.State.project.parameters.style;
            testCase.verifyEqual(style.baseFontSize, 11);
            testCase.verifyEqual(style.dataLineWidth, 2);
            testCase.verifyEqual(style.legendLocation, "northeast");
            runtime.applyTableEdit("legendTable", ...
                labkit.app.event.TableCellEdit(RowIndex=1, ColumnIndex=2, ...
                    PreviousValue="probe", NewValue="Edited series"));
            runtime.applyControlValue("dataLineWidth", 2.5);
            testCase.verifyEqual(string(preview.Legend.String), "Edited series");
            legendEditor = findall(runtime.figureHandle(), Tag="legendTable");
            testCase.verifyEqual(string(legendEditor.Data{1, 1}), "probe");
            testCase.verifyEqual(string(legendEditor.Data{1, 2}), "Edited series");
            runtime.applyTableEdit("legendTable", ...
                labkit.app.event.TableCellEdit(RowIndex=1, ColumnIndex=4, PreviousValue=[], NewValue=false));
            runtime.applyControlValue("legendVisible", "On");
            testCase.verifyEmpty(preview.Legend);
            runtime.applyTableEdit("legendTable", ...
                labkit.app.event.TableCellEdit(RowIndex=1, ColumnIndex=4, PreviousValue=[], NewValue=true));
            runtime.applyTableEdit("legendTable", ...
                labkit.app.event.TableCellEdit(RowIndex=1, ColumnIndex=3, PreviousValue=[], NewValue=1));
            testCase.verifyEqual(string(preview.Legend.String), "Edited series");
            runtime.invokeAction("exportFigureStyle");
            stylePath = fullfile(folder, "styled.mat");
            testCase.verifyTrue(isfile(stylePath));
            runtime.applyControlValue("tickFontSize", 8);
            runtime.invokeAction("importFigureStyle");
            testCase.verifyEqual( ...
                runtime.State.project.parameters.style.tickFontSize, 10);

            previousExport = runtime.State.project.results;
            capability = labkittest.nativeGraphicsCapability("clipboard");
            figuresBeforeCopy = findall(groot, Type="figure");
            if capability.Available
                runtime.invokeAction("copyFigure");
            else
                caught = [];
                try
                    runtime.invokeAction("copyFigure");
                catch cause
                    caught = cause;
                end
                testCase.assertNotEmpty(caught);
                testCase.verifyEqual(string(caught.identifier), ...
                    "labkit:app:runtime:ActionFailed");
                testCase.assertNotEmpty(caught.cause);
                testCase.verifyEqual(string(caught.cause{1}.identifier), ...
                    capability.ErrorIdentifier);
            end
            testCase.verifyEqual(runtime.State.project.results, previousExport);
            testCase.verifyEqual(findall(groot, Type="figure"), figuresBeforeCopy);
            copiedEvents = runtime.diagnosticSnapshot().events;
            testCase.verifyEqual(any(string({copiedEvents.eventName}) == ...
                "figure_studio.figure_copied"), capability.Available);
            runtime.invokeAction("exportPng");
            testCase.verifyTrue(isfile(outputPath));
            runtime.invokeAction("exportSvg");
            testCase.verifyTrue(isfile(svgPath));
            runtime.invokeAction("exportJpg");
            testCase.verifyTrue(isfile(jpgPath));
            runtime.invokeAction("saveFig");
            testCase.verifyTrue(isfile(figPath));
            savedFigure = openfig(figPath, 'invisible');
            savedCleanup = onCleanup(@() delete(savedFigure));
            savedLegend = findall(savedFigure, Type="legend");
            testCase.verifyEqual(string(savedLegend.String), "Edited series");
            clear savedCleanup
            runtime.invokeAction("chooseOutputFolder");
            testCase.verifyEqual(runtime.State.project.parameters.outputFolder, ...
                string(folder));
            runtime.invokeAction("exportCurrent");
            testCase.verifyTrue(isfile( ...
                runtime.State.project.results.lastExport.outputPath));
            clear cleanup
        end

        function editsAnnotationsAsSelectableTransformableObjects(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            sourcePath = fullfile(folder, "objects.fig");
            writeProbe(sourcePath);
            definition = figure_studio.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createMatlabRuntime(definition, [], ...
                struct("alert", @(~, ~) []), journal);
            cleanup = onCleanup(@() runtime.close());
            runtime.applyFileSelection("figFiles", sourcePath, 1);

            runtime.applyControlValue("annotationKind", "Text");
            runtime.applyControlValue("annotationText", "Peak A");
            runtime.applyControlValue("annotationX1", 1.5);
            runtime.applyControlValue("annotationY1", 3.5);
            runtime.applyControlValue("annotationX2", 1.5);
            runtime.applyControlValue("annotationY2", 3.5);
            runtime.invokeAction("addAnnotation");
            runtime.applyControlValue("annotationText", "Peak B");
            runtime.applyControlValue("annotationX1", 2.5);
            runtime.applyControlValue("annotationY1", 2.5);
            runtime.invokeAction("addAnnotation");
            runtime.applyControlValue("annotationText", "Peak C");
            runtime.applyControlValue("annotationX1", 3.5);
            runtime.applyControlValue("annotationY1", 4.0);
            runtime.invokeAction("addAnnotation");
            document = runtime.State.session.editor.document;
            testCase.verifyEqual(sum( ...
                string({document.nodes.kind}) == "text"), 3);

            runtime.applyTableSelection("objectTable", [2 1]);
            objectTable = findall(runtime.figureHandle(), "Tag", "objectTable");
            tableData = objectTable.Data;
            oldName = tableData{2, 6};
            tableData{2, 6} = "Primary peak";
            runtime.applyTableEdit("objectTable", ...
                labkit.app.event.TableCellEdit(RowIndex=2, ColumnIndex=6, ...
                    PreviousValue=oldName, NewValue="Primary peak", ...
                    Data=tableData));
            runtime.applyInteraction("selectedObjectBounds", ...
                "interactionChanged", [1.25 3.25 0.75 0.5]);
            [bounds, available] = figure_studio.figureDocument.selectionBounds( ...
                runtime.State.session.editor.document, ...
                runtime.State.session.editor.document.selection);
            testCase.verifyTrue(available);
            testCase.verifyEqual(bounds(1:2) + bounds(3:4) ./ 2, ...
                [1.625 3.5], AbsTol=1e-10);
            testCase.verifyEqual(bounds(3:4), [eps eps], AbsTol=eps);

            runtime.applyTableSelection("objectTable", [2 1; 3 1; 4 1]);
            runtime.applyControlValue("objectStyleScope", "Selection");
            runtime.applyControlValue("objectStyleProperty", "FontSize");
            runtime.applyControlValue("objectStyleValue", "16");
            runtime.invokeAction("applyObjectStyle");
            selected = runtime.State.session.editor.document.selection;
            styled = figure_studio.figureDocument.effectiveStyle( ...
                runtime.State.session.editor.document, selected(1));
            testCase.verifyEqual(styled.FontSize, 16);
            runtime.invokeAction("resetObjectStyle");

            before = figure_studio.figureDocument.selectionBounds( ...
                runtime.State.session.editor.document, selected);
            runtime.applyControlValue("objectMoveX", 0.2);
            runtime.applyControlValue("objectMoveY", 0.3);
            runtime.applyControlValue("objectScaleX", 1.1);
            runtime.applyControlValue("objectScaleY", 1.2);
            runtime.invokeAction("applyObjectTransform");
            after = figure_studio.figureDocument.selectionBounds( ...
                runtime.State.session.editor.document, ...
                runtime.State.session.editor.document.selection);
            testCase.verifyNotEqual(after, before);

            runtime.invokeAction("alignObjectsLeft");
            runtime.invokeAction("alignObjectsCenter");
            runtime.invokeAction("alignObjectsRight");
            runtime.invokeAction("alignObjectsBottom");
            runtime.invokeAction("alignObjectsMiddle");
            runtime.invokeAction("alignObjectsTop");
            runtime.invokeAction("distributeObjectsH");
            runtime.invokeAction("distributeObjectsV");
            runtime.invokeAction("groupObjects");
            groupId = runtime.State.session.editor.document.selection;
            testCase.verifyTrue(startsWith(groupId, "group-"));
            runtime.invokeAction("ungroupObjects");
            testCase.verifyNumElements( ...
                runtime.State.session.editor.document.selection, 3);
            count = numel(runtime.State.session.editor.document.nodes);
            runtime.invokeAction("duplicateObjects");
            testCase.verifyEqual(numel( ...
                runtime.State.session.editor.document.nodes), count + 3);
            runtime.invokeAction("objectsToFront");
            runtime.invokeAction("objectsForward");
            runtime.invokeAction("objectsBackward");
            runtime.invokeAction("objectsToBack");
            runtime.invokeAction("deleteAnnotations");
            testCase.verifyEqual(numel( ...
                runtime.State.session.editor.document.nodes), count);
            clear cleanup
        end

        function editsAndArrangesARealMultipanelFigure(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            sourcePath = fullfile(folder, "panels.fig");
            writeMultiPanelProbe(sourcePath);
            definition = figure_studio.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createMatlabRuntime(definition, [], ...
                struct("alert", @(~, ~) []), journal);
            cleanup = onCleanup(@() runtime.close());
            runtime.applyFileSelection("figFiles", sourcePath, 1);
            testCase.verifyNumElements( ...
                runtime.State.session.editor.document.panels, 3);
            panelChoices = runtime.State.session.cache.sourcePanelChoices;
            runtime.applyControlValue("sourcePanel", panelChoices(2));
            testCase.verifyEqual(runtime.State.session.selection.panel, ...
                panelChoices(2));

            runtime.applyControlValue("documentWidth", 900);
            runtime.applyControlValue("documentHeight", 700);
            runtime.applyControlValue("paddingLeft", 30);
            runtime.applyControlValue("paddingRight", 20);
            runtime.applyControlValue("paddingTop", 25);
            runtime.applyControlValue("paddingBottom", 15);
            canvas = runtime.State.session.editor.document.canvas;
            testCase.verifyEqual([canvas.width canvas.height], [900 700]);
            testCase.verifyEqual(canvas.padding, [30 20 25 15]);

            runtime.applyTableSelection("panelTable", [1 1]);
            panelTable = findall(runtime.figureHandle(), "Tag", "panelTable");
            tableData = panelTable.Data;
            oldName = tableData{1, 1};
            tableData{1, 1} = "Overview";
            runtime.applyTableEdit("panelTable", ...
                labkit.app.event.TableCellEdit(RowIndex=1, ColumnIndex=1, ...
                    PreviousValue=oldName, NewValue="Overview", Data=tableData));
            runtime.invokeAction("duplicatePanels");
            testCase.verifyNumElements( ...
                runtime.State.session.editor.document.panels, 4);
            runtime.invokeAction("deletePanels");
            testCase.verifyNumElements( ...
                runtime.State.session.editor.document.panels, 3);

            runtime.applyTableSelection("panelTable", [1 1; 2 1; 3 1]);
            runtime.invokeAction("autoGridPanels");
            runtime.invokeAction("alignPanelsLeft");
            runtime.invokeAction("alignPanelsRight");
            runtime.invokeAction("alignPanelsTop");
            runtime.invokeAction("alignPanelsBottom");
            runtime.invokeAction("equalPanelWidth");
            runtime.invokeAction("equalPanelHeight");
            runtime.invokeAction("distributePanelsH");
            runtime.invokeAction("distributePanelsV");
            geometry = vertcat( ...
                runtime.State.session.editor.document.panels.geometry);
            testCase.verifyEqual(geometry(:, 3), ...
                repmat(geometry(1, 3), 3, 1), AbsTol=1e-12);
            testCase.verifyEqual(geometry(:, 4), ...
                repmat(geometry(1, 4), 3, 1), AbsTol=1e-12);
            testCase.verifyTrue(all(isfinite(geometry), "all"));
            clear cleanup
        end
    end
end

function writeProbe(path)
figureValue = figure(Visible="off");
cleanup = onCleanup(@() delete(figureValue));
axesValue = axes(Parent=figureValue);
plot(axesValue, 1:4, [1 3 2 4], DisplayName="probe");
title(axesValue, "Probe");
axesValue.XLim = [1.75 2.25];
savefig(figureValue, path);
clear cleanup
end

function writeMultiPanelProbe(path)
figureValue = figure(Visible="off");
cleanup = onCleanup(@() delete(figureValue));
layout = tiledlayout(figureValue, 1, 3);
for index = 1:3
    axesValue = nexttile(layout);
    plot(axesValue, 1:4, [1 3 2 4] + index, ...
        DisplayName="trace " + index);
    title(axesValue, "Panel " + index);
end
savefig(figureValue, path);
clear cleanup
end

function filepath = exportPathForFilter(folder, filters)
extension = erase(string(filters(1)), "*");
filepath = fullfile(folder, "styled" + extension);
end
