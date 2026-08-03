classdef FigureStudioWorkflowSpec < matlab.unittest.TestCase
    %FIGURESTUDIOWORKFLOWSPEC Specify the bounded FIG-preview-export workflow.

    methods (TestMethodSetup)
        function keepNativeRuntimeHidden(testCase)
            previous = getenv("LABKIT_GUI_TEST_MODE");
            testCase.addTeardown(@setenv, "LABKIT_GUI_TEST_MODE", previous);
            setenv("LABKIT_GUI_TEST_MODE", "hidden");
        end
    end

    methods (Test, TestTags = {'Contract:presentation', 'Env:hidden-gui'})
        function loadsAFigureIntoTheInteractivePreviewAndExportsPng(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            sourcePath = fullfile(folder, "probe.fig");
            outputPath = fullfile(folder, "styled.png");
            svgPath = fullfile(folder, "styled.svg");
            writeProbe(sourcePath);
            backend = struct( ...
                "chooseOutputFile", @(filters, ~) ...
                    labkit.app.dialog.Choice( ...
                    exportPathForFilter(folder, filters)), ...
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
            testCase.verifyEqual(string(export.Enable), "on");
            runtime.invokeAction("exportPng");
            testCase.verifyTrue(isfile(outputPath));
            runtime.invokeAction("exportSvg");
            testCase.verifyTrue(isfile(svgPath));
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

function filepath = exportPathForFilter(folder, filters)
extension = erase(string(filters(1)), "*");
filepath = fullfile(folder, "styled" + extension);
end
