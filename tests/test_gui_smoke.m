function test_gui_smoke()
%TEST_GUI_SMOKE Verify GUI entry points can launch.

    assertUifigureAvailable();
    root = fileparts(fileparts(mfilename('fullpath')));
    legacyDir = fullfile(root, 'legacy');

    entries = { ...
        'gamry_multiDTA_plot_export_gui', 'Gamry Multi-DTA Plot Export GUI'; ...
        'gamry_EIS_multiDTA_plot_gui', 'Gamry EIS Multi-DTA Plot GUI'; ...
        'gamry_CV_CSC_dta_gui', 'Gamry DTA GUI (literature CSC)'; ...
        'gamry_VT_resistance_gui', 'Gamry VT Steady Resistance GUI'; ...
        'gamry_CIC_VT_gui_paperlabels', 'Gamry CIC GUI (Voltage Transient)'; ...
        'gamrywb_EIS_app', 'Gamry EIS Multi-DTA Plot GUI'; ...
        'gamrywb_CSC_app', 'Gamry DTA GUI (literature CSC)'; ...
        'gamrywb_VTResistance_app', 'Gamry VT Steady Resistance GUI'; ...
        'gamrywb_CIC_app', 'Gamry CIC GUI (Voltage Transient)'};

    cleanup = onCleanup(@closeAllFigures);
    for k = 1:size(entries, 1)
        closeAllFigures();
        entryName = entries{k, 1};
        expectedTitle = entries{k, 2};

        feval(entryName);
        drawnow;
        assert(~pathContains(legacyDir), 'Entry point %s should not leave legacy/ on the MATLAB path.', entryName);

        figs = findall(groot, 'Type', 'figure');
        names = getFigureNames(figs);
        assert(any(strcmp(names, expectedTitle)), ...
            'GUI entry point %s did not create expected figure "%s".', entryName, expectedTitle);
    end
end

function tf = pathContains(folder)
    paths = strsplit(path, pathsep);
    tf = any(strcmp(paths, folder));
end

function assertUifigureAvailable()
    try
        f = uifigure('Visible', 'off', 'Name', 'gamrywb_gui_smoke_probe');
        delete(f);
    catch ME
        error('GUI smoke tests require MATLAB uifigure support: %s', ME.message);
    end
end

function names = getFigureNames(figs)
    names = cell(size(figs));
    for i = 1:numel(figs)
        names{i} = figs(i).Name;
    end
end

function closeAllFigures()
    figs = findall(groot, 'Type', 'figure');
    if ~isempty(figs)
        delete(figs);
    end
    drawnow;
end
