function test_startup_boundaries()
%TEST_STARTUP_BOUNDARIES Check startup path and root entrypoint boundaries.

    root = fileparts(fileparts(mfilename('fullpath')));

    assert(exist(fullfile(root, 'startup_gamrywb.m'), 'file') == 2, 'startup_gamrywb.m is missing.');
    assert(exist(fullfile(root, '+gamrywb', '+dta', 'loadFile.m'), 'file') == 2, 'DTA facade is missing.');
    assert(exist(fullfile(root, 'apps', 'electrochem'), 'dir') == 7, ...
        'Electrochem app folder should exist under apps/.');
    assert(exist(fullfile(root, 'legacy'), 'dir') == 0, 'legacy/ should be removed after app entry points are package-backed.');
    assert(pathContains(fullfile(root, 'apps')), 'startup_gamrywb should add apps/ to the path.');
    assert(pathContains(fullfile(root, 'apps', 'electrochem')), ...
        'startup_gamrywb should add nested app category folders to the path.');

    removedRootNames = { ...
        'gamry_CIC_VT_gui_paperlabels', ...
        'gamry_VT_resistance_gui', ...
        'gamry_CV_CSC_dta_gui', ...
        'gamry_EIS_multiDTA_plot_gui', ...
        'gamry_multiDTA_plot_export_gui'};

    for i = 1:numel(removedRootNames)
        rootFile = fullfile(root, [removedRootNames{i} '.m']);

        assert(exist(rootFile, 'file') == 0, ['Root legacy wrapper should be removed: ' removedRootNames{i}]);
        assert(isempty(which(removedRootNames{i})), ['Original legacy command should not resolve by default: ' removedRootNames{i}]);
    end

    assert(exist(demoFixturePath('cv_cyclic_voltammetry_pt_reference.DTA'), 'file') == 2, ...
        'Demo fixture cv_cyclic_voltammetry_pt_reference.DTA is missing.');

    previousDir = pwd;
    cleaner = onCleanup(@() cd(previousDir));
    cd(tempdir);
    entries = appEntryManifest();
    for i = 1:size(entries, 1)
        assert(~isempty(which(entries{i, 1})), ...
            ['App entry point should resolve without cd into apps/: ' entries{i, 1}]);
    end
end

function tf = pathContains(folder)
    paths = strsplit(path, pathsep);
    tf = any(strcmp(paths, folder));
end
