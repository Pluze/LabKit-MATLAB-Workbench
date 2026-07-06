classdef GuiLayoutFigureStudioTest < matlab.uitest.TestCase
    %GUILAYOUTFIGURESTUDIOTEST Verify Figure Studio launch and controls.

    methods (Test, TestTags = {'GUI', 'Structural', 'Workflow'})
        function figure_studio_launches_with_style_library(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            fig = labkit_FigureStudio_app();
            assert(~isempty(fig) && isvalid(fig), ...
                'Figure Studio should launch as a LabKit app.');
            driver = labkitWorkflowDriver(fig);
            ui = driver.registry();
            assert(isfield(ui.controls, 'stylePreset') && ...
                isfield(ui.controls, 'figFiles') && ...
                isfield(ui.controls, 'preview'), ...
                'Figure Studio should expose style mode, FIG files, and preview axes.');
            assert(isequal(string(ui.controls.stylePreset.valueHandle.Items), ...
                ["LabKit figure", "FIG default"]), ...
                'Figure Studio should expose only the LabKit style and FIG default modes.');
            assert(labkit.ui.view.getValue(ui, "canvasWidth") == 720 && ...
                labkit.ui.view.getValue(ui, "canvasHeight") == 540 && ...
                labkit.ui.view.getValue(ui, "baseFontSize") == 36 && ...
                labkit.ui.view.getValue(ui, "dataLineWidth") == 3 && ...
                labkit.ui.view.getValue(ui, "axesLineWidth") == 3, ...
                'Figure Studio default single-panel style should match the measured reference panel proportions.');
            setNumericControl(fig, 'baseFontSize', 24);
            ui = driver.registry();
            assert(labkit.ui.view.getValue(ui, "titleFontSize") == 24 && ...
                labkit.ui.view.getValue(ui, "labelFontSize") == 24 && ...
                labkit.ui.view.getValue(ui, "tickFontSize") == 24, ...
                'All font should synchronize title, label, and tick font controls.');
            setNumericControl(fig, 'titleFontSize', 32);
            assert(labkit.ui.view.getValue(driver.registry(), "titleFontSize") == 32, ...
                'Single font controls should be independently adjustable after global sync.');
            setDropdownControl(fig, 'aspectPreset', 'Custom');
            setNumericControl(fig, 'canvasWidth', 1550);
            setNumericControl(fig, 'canvasHeight', 777);
            ui = driver.registry();
            assert(strcmp(string(labkit.ui.view.getValue(ui, "aspectPreset")), "Custom") && ...
                labkit.ui.view.getValue(ui, "canvasWidth") == 1550 && ...
                labkit.ui.view.getValue(ui, "canvasHeight") == 777, ...
                'Custom aspect should preserve independently edited canvas dimensions.');
            folder = tempname();
            mkdir(folder);
            folderCleanup = onCleanup(@() removeTempFolder(folder));
            figPath = fullfile(folder, 'probe.fig');
            saveProbeFigure(figPath);
            driver.chooseFiles('figFiles', folder);
            driver.click('Add FIG files or scan folder');
            waitForNotBusy(fig);
            pause(2);
            drawnow;
            assert(any(contains(driver.fileListItems('figFiles'), "probe.fig")), ...
                'Figure Studio should scan selected folders for MATLAB FIG files.');
            assert(driver.previewChildCount('preview') > 0 && ...
                driver.enabled('exportCurrent'), ...
                'Figure Studio should auto-open scanned FIG files into a styleable preview.');
            ax = driver.registry().controls.preview.axesById.main;
            assert(isappdata(ax, 'labkitFigureStudioCanvasFrame'), ...
                'Figure Studio preview should track a fixed canvas frame.');
            frameBefore = getappdata(ax, 'labkitFigureStudioCanvasFrame');
            fig.Position(3:4) = max([900 620], fig.Position(3:4) - [420 260]);
            pause(0.8);
            drawnow;
            frameAfter = getappdata(ax, 'labkitFigureStudioCanvasFrame');
            assert(isfield(frameAfter, 'scale') && frameAfter.scale <= frameBefore.scale && ...
                abs(frameAfter.ratio - frameBefore.ratio) < 1e-12, ...
                'Figure Studio should preserve canvas ratio and avoid enlarging preview scale when the app window resizes.');
            assert(~isfield(driver.registry().controls, 'applyStyle'), ...
                'Figure Studio should apply style changes immediately without an Apply button.');
            assertNoDuplicateSpecIds(fig);
        end

        function figure_studio_accepts_popout_axes_handoff(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            sourceFig = figure('Visible', 'off');
            sourceAx = axes('Parent', sourceFig);
            plot(sourceAx, 1:3, [1 4 2], 'DisplayName', 'probe');
            title(sourceAx, 'Probe');
            pbaspect(sourceAx, [2 1 1]);

            fig = labkit_FigureStudio_app("axes", sourceAx);
            driver = labkitWorkflowDriver(fig);
            assert(driver.previewChildCount('preview') > 0 && ...
                driver.enabled('exportCurrent'), ...
                'Figure Studio should enable styling after axes handoff.');
            ui = driver.registry();
            canvasRatio = double(labkit.ui.view.getValue(ui, "canvasWidth")) / ...
                double(labkit.ui.view.getValue(ui, "canvasHeight"));
            assert(abs(canvasRatio - 2) < 0.02 && ...
                strcmp(string(labkit.ui.view.getValue(ui, "aspectPreset")), "Custom"), ...
                'Figure Studio axes handoff should preserve the source plot box ratio as a custom canvas.');
        end

        function popout_send_to_studio_copies_plot_content(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            sourceFig = figure('Visible', 'off', 'Name', 'Source Plot');
            sourceAx = axes('Parent', sourceFig);
            plot(sourceAx, 1:3, [2 1 4], 'DisplayName', 'source');
            title(sourceAx, 'Source Plot');

            popoutFig = labkit.ui.tool.popoutAxes(sourceAx, "Title", "Source Plot");
            hookCleanup = onCleanup(@() removeStudioHook());
            setappdata(groot, 'labkitFigureStudioLauncher', ...
                @(ax) labkit_FigureStudio_app("axes", ax));
            studioTool = findall(popoutFig, 'Tag', 'labkitAxesPopoutStudioTool');
            assert(~isempty(studioTool), ...
                'Popout should expose a Studio handoff button.');
            h.invokeCallback(studioTool(1), 'Callback');
            drawnow;

            studioFig = findall(groot, 'Type', 'figure', 'Name', ...
                'Figure Studio v0.1.0 (2026-07-06)');
            assert(~isempty(studioFig), ...
                'Popout Studio handoff should launch Figure Studio.');
            driver = labkitWorkflowDriver(studioFig(1));
            assert(driver.previewChildCount('preview') > 0 && ...
                driver.enabled('exportCurrent'), ...
                'Popout Studio handoff should copy plot content into Studio.');
        end
    end
end

function removeStudioHook()
    if isappdata(groot, 'labkitFigureStudioLauncher')
        rmappdata(groot, 'labkitFigureStudioLauncher');
    end
end

function waitForNotBusy(fig)
    deadline = tic;
    while isvalid(fig) && isappdata(fig, 'labkitUiBusyDepth') && ...
            getappdata(fig, 'labkitUiBusyDepth') > 0 && toc(deadline) < 45
        pause(0.1);
        drawnow;
    end
end

function setNumericControl(fig, id, value)
    ui = getappdata(fig, 'labkitUiRegistry');
    control = ui.controls.(char(id));
    previous = control.valueSpinner.Value;
    control.valueSpinner.Value = value;
    control.valueSpinner.ValueChangedFcn(control.valueSpinner, ...
        struct('PreviousValue', previous));
    drawnow;
end

function setDropdownControl(fig, id, value)
    ui = getappdata(fig, 'labkitUiRegistry');
    control = ui.controls.(char(id));
    previous = control.valueHandle.Value;
    control.valueHandle.Value = value;
    control.valueHandle.ValueChangedFcn(control.valueHandle, ...
        struct('PreviousValue', previous));
    drawnow;
end

function saveProbeFigure(filepath)
    f = figure('Visible', 'off');
    cleanup = onCleanup(@() delete(f));
    ax = axes('Parent', f);
    plot(ax, 1:4, [1 3 2 4], 'DisplayName', 'probe');
    title(ax, 'Probe');
    savefig(f, filepath);
end

function removeTempFolder(folder)
    if isfolder(folder)
        rmdir(folder, 's');
    end
end

function assertNoDuplicateSpecIds(fig)
    tags = string(get(findall(fig), 'Tag'));
    tags = tags(strlength(tags) > 0);
    [uniqueTags, ~, group] = unique(tags);
    counts = accumarray(group, 1);
    duplicateTags = uniqueTags(counts > 1);
    assert(~any(duplicateTags == "figures"), ...
        'Figure Studio should not reuse the figures tab id as a control id.');
end
