classdef GuiLayoutFlirThermalTest < matlab.uitest.TestCase
    %GUILAYOUTFLIRTHERMALTEST Verify FLIR thermal GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function flir_thermal_layout(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            fig = h.launchFigure('labkit_FLIRThermal_app', ...
                'FLIR Thermal Postprocess');
            h.assertStandardWorkbenchLayout(fig);
            h.assertButtonContract(fig, {'Add FLIR files or folder', ...
                'Remove selected', 'Clear files', 'Previous image', ...
                'Next image', 'Auto range', 'Choose folder', 'Export current', ...
                'Export all'});
            h.assertDropdownGroups(fig, [ ...
                h.dropdownGroup({'turbo', 'iron', 'hot', 'parula', 'gray'}, 1), ...
                h.dropdownGroup({'PNG', 'TIFF', 'JPEG'}, 1), ...
                h.dropdownGroup({'Thermal', 'Raw signal'}, 1)]);
            h.assertTabTitles(fig, {'Files + Display + Export', 'Details', 'Log'});
            h.assertAxesContract(fig, { ...
                h.axesSpec('Clean thermal image', '', ''), ...
                h.axesSpec('Scale', '', '')});

            h.closeAllFigures();
            [fig, debug] = labkit_FLIRThermal_app("debug");
            drawnow;
            assert(debug.enabled && debug.traceEnabled, ...
                'FLIR Thermal debug launch should return an enabled trace logger.');
            assertAnyTextAreaContains(h, fig, 'FLIR thermal debug trace enabled', ...
                'FLIR Thermal debug launch should mirror trace lines into the visible Log tab.');
        end
    end
end

function assertAnyTextAreaContains(h, fig, needle, message)
    areas = h.findControlsByClass(fig, 'TextArea');
    values = strings(1, numel(areas));
    for k = 1:numel(areas)
        values(k) = strjoin(string(areas{k}.Value), newline);
    end
    assert(any(contains(values, needle)), message);
end
