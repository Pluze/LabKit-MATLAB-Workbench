function test_dtaFacade()
%TEST_DTAFACADE Verify GUI-free DTA type detection and loading facade.

    root = fileparts(fileparts(mfilename('fullpath')));
    chronoFile = fullfile(root, 'demo', 'chrono_chronopot_current_pulse_0p2ms.DTA');
    eisFile = fullfile(root, 'demo', 'eis_potentiostatic_zcurve.DTA');
    cvctFile = fullfile(root, 'demo', 'cv_cyclic_voltammetry_pt_reference.DTA');

    discoveredFiles = gamrywb.dta.findFiles(fullfile(root, 'demo'));
    assert(numel(discoveredFiles) >= 8, 'DTA facade should recursively discover demo DTA fixtures.');
    assert(all(endsWith(lower(string(discoveredFiles)), '.dta')), ...
        'DTA facade discovery should return only DTA files.');
    assert(any(strcmp(discoveredFiles, chronoFile)), ...
        'DTA facade discovery should include the current-controlled chrono fixture.');

    assert(gamrywb.dta.detectType(chronoFile) == "chrono", 'Chrono fixture should detect as chrono.');
    assert(gamrywb.dta.detectType(eisFile) == "eis", 'EIS fixture should detect as eis.');
    assert(gamrywb.dta.detectType(cvctFile) == "cvct", 'CV/CT fixture should detect as cvct.');

    [chronoItem, chronoStatus] = gamrywb.dta.loadFile(chronoFile, "chrono");
    assert(chronoStatus.ok, chronoStatus.message);
    assert(chronoStatus.kind == "chrono", 'Chrono status kind should be chrono.');
    assert(chronoItem.type == "chrono", 'Chrono item type should be preserved.');
    assert(isfield(chronoItem, 't') && isfield(chronoItem, 'Vf') && isfield(chronoItem, 'Im'), ...
        'Chrono facade should preserve legacy-compatible vectors.');

    [eisItem, eisStatus] = gamrywb.dta.loadFile(eisFile);
    assert(eisStatus.ok, eisStatus.message);
    assert(eisStatus.kind == "eis", 'Auto-loaded EIS status kind should be eis.');
    assert(eisItem.type == "eis", 'EIS item type should be preserved.');
    assert(isfield(eisItem, 'Freq') && isfield(eisItem, 'Zreal') && isfield(eisItem, 'Zimag'), ...
        'EIS facade should preserve legacy-compatible impedance vectors.');

    [cvctItem, cvctStatus] = gamrywb.dta.loadFile(cvctFile, "cvct");
    assert(cvctStatus.ok, cvctStatus.message);
    assert(cvctStatus.kind == "cvct", 'CV/CT status kind should be cvct.');
    assert(cvctItem.type == "cvct", 'CV/CT item type should be set.');
    assert(~isempty(cvctItem.curves), 'CV/CT item should include parsed curves.');
    assert(isfield(cvctItem, 'scanRate') && isfield(cvctItem, 'scanRate_V_per_s'), ...
        'CV/CT item should expose scan rate fields.');

    [mismatchItem, mismatchStatus] = gamrywb.dta.loadFile(eisFile, "chrono");
    assert(isempty(mismatchItem), 'Mismatched DTA load should not return an item.');
    assert(~mismatchStatus.ok, 'Mismatched DTA load should return failed status.');
    assert(mismatchStatus.kind == "eis", 'Mismatch status should report detected kind.');
    assert(contains(mismatchStatus.message, 'Expected chrono DTA'), ...
        'Mismatch status should explain expected kind.');

    [missingItem, missingStatus] = gamrywb.dta.loadFile(fullfile(root, 'demo', 'missing_file.DTA'), "auto");
    assert(isempty(missingItem), 'Missing file load should not return an item.');
    assert(~missingStatus.ok, 'Missing file load should return failed status.');
    assert(contains(missingStatus.message, 'File not found'), 'Missing file status should be readable.');

    [items, report] = gamrywb.dta.loadFiles({chronoFile, eisFile, cvctFile}, "auto");
    assert(numel(items) == 3, 'Batch auto-load should return all valid items.');
    assert(report.nRequested == 3 && report.nLoaded == 3 && report.nFailed == 0, ...
        'Batch report counts should match successful loads.');
    assert(all([report.statuses.ok]), 'Batch statuses should be successful.');

    [folderItems, folderReport] = gamrywb.dta.loadFolder(fullfile(root, 'demo'), "auto");
    assert(numel(folderItems) == folderReport.nLoaded, ...
        'Folder load should return one item per successful load.');
    assert(folderReport.nDiscovered == numel(folderReport.filepaths), ...
        'Folder load report should expose discovered file count.');
    assert(folderReport.nRequested == folderReport.nDiscovered, ...
        'Folder load should request every discovered DTA file.');
    assert(strcmp(folderReport.folder, fullfile(root, 'demo')), ...
        'Folder load report should preserve the requested folder.');
end
