function test_gui_smoke()
%TEST_GUI_SMOKE Verify GUI entry points can launch.

    assertUifigureAvailable();
    root = fileparts(fileparts(mfilename('fullpath')));
    legacyDir = fullfile(root, 'legacy');

    entries = appEntryManifest();

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
        f = uifigure('Visible', 'off', 'Name', 'labkit_gui_smoke_probe');
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
