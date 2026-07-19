classdef GuiLayoutFigureStudioTest < matlab.unittest.TestCase
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
            assert(testui.control.getValue(ui, "canvasWidth") == 720 && ...
                testui.control.getValue(ui, "canvasHeight") == 540 && ...
                testui.control.getValue(ui, "baseFontSize") == 36 && ...
                testui.control.getValue(ui, "dataLineWidth") == 3 && ...
                testui.control.getValue(ui, "axesLineWidth") == 3, ...
                'Figure Studio default single-panel style should match the measured reference panel proportions.');
            setNumericControl(fig, 'baseFontSize', 24);
            ui = driver.registry();
            assert(testui.control.getValue(ui, "titleFontSize") == 24 && ...
                testui.control.getValue(ui, "labelFontSize") == 24 && ...
                testui.control.getValue(ui, "tickFontSize") == 24, ...
                'All font should synchronize title, label, and tick font controls.');
            setNumericControl(fig, 'titleFontSize', 32);
            assert(testui.control.getValue(driver.registry(), "titleFontSize") == 32, ...
                'Single font controls should be independently adjustable after global sync.');
            setDropdownControl(fig, 'aspectPreset', 'Custom');
            setNumericControl(fig, 'canvasWidth', 1550);
            setNumericControl(fig, 'canvasHeight', 777);
            ui = driver.registry();
            assert(strcmp(string(testui.control.getValue(ui, "aspectPreset")), "Custom") && ...
                testui.control.getValue(ui, "canvasWidth") == 1550 && ...
                testui.control.getValue(ui, "canvasHeight") == 777, ...
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
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            testCase.verifyEqual(runtime.definition.contractVersion, 2, ...
                'Figure Studio must execute through Runtime V2.');
            testCase.verifyEqual(func2str(runtime.definition.start), ...
                'figure_studio.initializeWorkbench', ...
                'Figure Studio should declare its post-layout initializer explicitly.');
            testCase.verifyFalse(containsGraphicsHandle(runtime.state.project), ...
                'Figure Studio projects must not retain axes or other graphics handles.');
            ax = driver.registry().controls.preview.axesById.main;
            assert(~contains(join(string(ax.Title.String), " "), " | file "), ...
                'Figure Studio should not style framework file-title context as plot content.');
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

            pngPath = fullfile(folder, 'styled-probe.png');
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            runtime.request.outputFileChooser = @(~, ~, ~) deal( ...
                'styled-probe.png', folder);
            runtime.request.outputFolderChooser = @(~, ~) folder;
            setappdata(fig, 'labkitUiAppRuntime', runtime);
            driver.click('PNG');
            testCase.verifyTrue(isfile(pngPath));
            testCase.verifyTrue(isfile(fullfile(folder, ...
                'figure_studio.labkit.json')), ...
                'Quick exports should add the standard Figure Studio manifest.');
            driver.click('Choose output folder');
            driver.click('Export data + script');
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            packagePath = string(runtime.state.project.results.lastExport.path);
            testCase.verifyTrue(isfolder(packagePath));
            testCase.verifyTrue(isfile(fullfile(packagePath, ...
                'figure_studio.labkit.json')), ...
                'Package exports should add the standard Figure Studio manifest.');
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
            waitForNotBusy(fig);
            pause(1);
            drawnow;
            driver = labkitWorkflowDriver(fig);
            assert(driver.previewChildCount('preview') > 0 && ...
                driver.enabled('exportCurrent'), ...
                'Figure Studio should enable styling after axes handoff.');
            ui = driver.registry();
            canvasRatio = double(testui.control.getValue(ui, "canvasWidth")) / ...
                double(testui.control.getValue(ui, "canvasHeight"));
            assert(abs(canvasRatio - 2) < 0.02 && ...
                strcmp(string(testui.control.getValue(ui, "aspectPreset")), "Custom"), ...
                'Figure Studio axes handoff should preserve the source plot box ratio as a custom canvas.');

            folder = tempname;
            mkdir(folder);
            folderCleanup = onCleanup(@() removeTempFolder(folder));
            projectPath = fullfile(folder, 'figure-studio-project.mat');
            labkit.ui.runtime.saveState(fig, projectPath);
            saved = load(projectPath, 'labkitProject');
            testCase.verifyEqual(saved.labkitProject.app.payloadVersion, 1);
            testCase.verifyFalse(isfield(saved.labkitProject.payload, 'session'), ...
                'Figure Studio projects must exclude runtime resources and caches.');
            testCase.verifyFalse(containsGraphicsHandle(saved.labkitProject.payload), ...
                'Serialized axes handoff data must not contain graphics handles.');
            testCase.verifyNotEmpty(saved.labkitProject.payload.annotations.embeddedPlot, ...
                'Axes handoff plot data should remain durable inside the project.');
            labkit.ui.runtime.loadState(fig, projectPath);
            h.waitForUiIdle(fig);
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            testCase.verifyNotEmpty(runtime.state.session.cache.plotData, ...
                'Project reopen should rebuild the plot session cache.');
            testCase.verifyGreaterThan(driver.previewChildCount('preview'), 0, ...
                'Project reopen should redraw the embedded axes handoff.');
        end

        function figure_studio_waits_for_stable_preview_canvas(~)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            fig = uifigure('Visible', 'off', 'Position', [100 100 1200 800]);
            grid = uigridlayout(fig, [3 3]);
            ax = uiaxes(grid);
            ax.Layout.Row = 2;
            ax.Layout.Column = 2;
            plot(ax, linspace(0, 30, 200), sin(linspace(0, 30, 200)));

            style = figure_studio.styleLibrary.styleForPreset("LabKit figure");
            style.previewScale = true;
            figure_studio.resultFiles.applyFigureStyle(ax, style);

            frame = getappdata(ax, 'labkitFigureStudioCanvasFrame');
            assert(ax.Layout.Row == 2 && ax.Layout.Column == 2, ...
                'Figure Studio should place the managed canvas in the centered preview grid cell.');
            if isfield(frame, 'pixelPosition')
                frameIsStable = frame.pixelPosition(3) > 100 && ...
                    frame.pixelPosition(4) > 100;
            else
                frameIsStable = frame.position(3) > 0.5 && frame.position(4) > 0.5;
            end
            assert(frame.scale > 0.5 && frameIsStable, ...
                'Figure Studio should not freeze preview canvas size from the initial 100x100 uigridlayout measurement.');
        end

        function popout_send_to_studio_copies_plot_content(~)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            sourceFig = figure('Visible', 'off', 'Name', 'Source Plot');
            sourceAx = axes('Parent', sourceFig);
            plot(sourceAx, 1:3, [2 1 4], 'DisplayName', 'source');
            title(sourceAx, 'Source Plot');

            labkit.app.plot.enablePopout(sourceAx);
            menu = findall(sourceAx.ContextMenu, 'Type', 'uimenu', ...
                'Tag', 'labkitAxesPopoutMenu');
            menu(1).MenuSelectedFcn(menu(1), []);
            popoutFig = findall(groot, 'Type', 'figure', 'Name', 'Source Plot');
            popoutFig = popoutFig(1);
            hookCleanup = onCleanup(@() removeStudioHook());
            setappdata(groot, 'labkitFigureStudioLauncher', ...
                @(ax) labkit_FigureStudio_app("axes", ax));
            studioTool = findall(popoutFig, 'Tag', 'labkitAxesPopoutStudioTool');
            assert(~isempty(studioTool), ...
                'Popout should expose a Studio handoff button.');
            h.invokeCallback(studioTool(1), 'Callback');
            drawnow;

            studioFig = figureStudioFigures();
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

function figures = figureStudioFigures()
    allFigures = findall(groot, 'Type', 'figure');
    keep = false(size(allFigures));
    for k = 1:numel(allFigures)
        keep(k) = contains(string(allFigures(k).Name), "Figure Studio");
    end
    figures = allFigures(keep);
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
    pause(0.65);
    waitForNotBusy(fig);
    drawnow;
end

function setDropdownControl(fig, id, value)
    ui = getappdata(fig, 'labkitUiRegistry');
    control = ui.controls.(char(id));
    previous = control.valueHandle.Value;
    control.valueHandle.Value = value;
    control.valueHandle.ValueChangedFcn(control.valueHandle, ...
        struct('PreviousValue', previous));
    pause(0.65);
    waitForNotBusy(fig);
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

function tf = containsGraphicsHandle(value)
    tf = isa(value, 'matlab.graphics.Graphics');
    if tf
        return;
    end
    if isstruct(value)
        names = fieldnames(value);
        for index = 1:numel(value)
            for name = names.'
                if containsGraphicsHandle(value(index).(name{1}))
                    tf = true;
                    return;
                end
            end
        end
    elseif iscell(value)
        for index = 1:numel(value)
            if containsGraphicsHandle(value{index})
                tf = true;
                return;
            end
        end
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
