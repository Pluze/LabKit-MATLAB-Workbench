function test_appTemplates()
%TEST_APPTEMPLATES Verify the standard template programs keep narrow surfaces.

    root = fileparts(fileparts(mfilename('fullpath')));
    templateDir = fullfile(root, 'templates');

    guiOnly = fileread(fullfile(templateDir, 'gui_only_app_template.m'));
    assert(contains(guiOnly, 'gamrywb.ui.'), 'GUI-only template should use the GUI facade.');
    assert(~contains(guiOnly, 'gamrywb.dta.'), 'GUI-only template should not use the DTA facade.');
    assert(~contains(guiOnly, 'gamrywb.data.'), 'GUI-only template should not expose data helpers.');

    dtaOnly = fileread(fullfile(templateDir, 'dta_only_script_template.m'));
    assert(contains(dtaOnly, 'gamrywb.dta.'), 'DTA-only template should use the DTA facade.');
    assert(~contains(dtaOnly, 'gamrywb.ui.'), 'DTA-only template should not use GUI helpers.');
    assert(~contains(dtaOnly, 'gamrywb.data.'), 'DTA-only template should not expose data helpers.');

    guiDta = fileread(fullfile(templateDir, 'gui_dta_app_template.m'));
    assert(contains(guiDta, 'gamrywb.ui.'), 'GUI+DTA template should use the GUI facade.');
    assert(contains(guiDta, 'gamrywb.dta.'), 'GUI+DTA template should use the DTA facade.');
    assert(~contains(guiDta, 'gamrywb.data.'), 'GUI+DTA template should not expose data helpers.');
    assert(~contains(guiDta, 'gamrywb.io.'), 'GUI+DTA template should not call parser IO directly.');

    addpath(templateDir);
    cleanup = onCleanup(@() rmpath(templateDir)); %#ok<NASGU>
    summary = dta_only_script_template(demoFixturePath('chrono_chronopot_current_pulse_0p2ms.DTA'), "chrono");
    assert(summary.nLoaded == 1 && summary.nFailed == 0, ...
        'DTA-only template should run against a fixture through the DTA facade.');
    assert(summary.kinds(1) == "chrono", 'DTA-only template should report the loaded item kind.');
end
