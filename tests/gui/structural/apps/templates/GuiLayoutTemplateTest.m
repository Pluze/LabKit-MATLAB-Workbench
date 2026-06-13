classdef GuiLayoutTemplateTest < matlab.uitest.TestCase
    %GUILAYOUTTEMPLATETEST Verify the starter template app layout contract.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function templateAppLaunchesWithUi2Structure(testCase)
            setupLabKitTestPath();
            verify_template_app_layout();
        end
    end
end

function verify_template_app_layout()
    h = guiTestHelpers();
    h.assertUifigureAvailable();
    cleanup = onCleanup(@() h.closeAllFigures());

    fig = labkit_TemplateApp_app();
    drawnow;

    assert(strcmp(fig.Name, 'LabKit Template App'), ...
        'Template app should launch with its documented figure title.');
    h.assertFigureMinimumSize(fig, 1280, 760);
    h.assertTabTitles(fig, {'Setup', 'Review', 'Log', ...
        'Inputs', 'Options', 'Actions', 'Template Summary', 'Details'});
    h.assertButtonContract(fig, {'Choose files', 'Clear', ...
        'Run template step', 'Reset'});
    h.assertAnyTableColumns(fig, {'Field', 'Value'});

    close(fig);
    [debugFig, debug] = labkit_TemplateApp_app("__labkit_debug__", struct());
    drawnow;
    assert(isstruct(debug) && debug.enabled, ...
        'Template app debug launch should return an enabled debug context.');
    assert(debug.appName == "labkit_TemplateApp_app", ...
        'Template app debug context should preserve the app name.');
    assertVisibleDebugTrace(debugFig);
end

function assertVisibleDebugTrace(fig)
    controls = findall(fig);
    for k = 1:numel(controls)
        control = controls(k);
        if ~contains(class(control), 'TextArea')
            continue;
        end
        if any(contains(string(control.Value), 'debug trace enabled'))
            return;
        end
    end
    error('Template app should mirror debug trace lines into the visible Log tab.');
end
