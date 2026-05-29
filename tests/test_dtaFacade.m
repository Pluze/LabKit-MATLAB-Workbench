function test_dtaFacade()
%TEST_DTAFACADE Verify GUI-free DTA type detection and loading facade.

    demoDir = demoFixtureDir();
    chronoFile = demoFixturePath('chrono_chronopot_current_pulse_0p2ms.DTA');
    eisFile = demoFixturePath('eis_potentiostatic_zcurve.DTA');
    cvctFile = demoFixturePath('cv_cyclic_voltammetry_pt_reference.DTA');

    discoveredFiles = gamrywb.dta.findFiles(demoDir);
    assert(numel(discoveredFiles) >= 8, 'DTA facade should recursively discover demo DTA fixtures.');
    assert(all(endsWith(lower(string(discoveredFiles)), '.dta')), ...
        'DTA facade discovery should return only DTA files.');
    assert(any(strcmp(discoveredFiles, chronoFile)), ...
        'DTA facade discovery should include the current-controlled chrono fixture.');
    assert(isequal(gamrywb.dta.findFiles(string(demoDir)), discoveredFiles), ...
        'DTA facade discovery should accept scalar string folders.');
    assertInvalidFolderInput();

    assert(gamrywb.dta.detectType(chronoFile) == "chrono", 'Chrono fixture should detect as chrono.');
    assert(gamrywb.dta.detectType(eisFile) == "eis", 'EIS fixture should detect as eis.');
    assert(gamrywb.dta.detectType(cvctFile) == "cvct", 'CV/CT fixture should detect as cvct.');

    [chronoItem, chronoStatus] = gamrywb.dta.loadFile(chronoFile, "chrono");
    assertStatusFields(chronoStatus);
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
    assertStatusFields(mismatchStatus);
    assert(isempty(mismatchItem), 'Mismatched DTA load should not return an item.');
    assert(~mismatchStatus.ok, 'Mismatched DTA load should return failed status.');
    assert(mismatchStatus.kind == "eis", 'Mismatch status should report detected kind.');
    assert(contains(mismatchStatus.message, 'Expected chrono DTA'), ...
        'Mismatch status should explain expected kind.');

    [missingItem, missingStatus] = gamrywb.dta.loadFile(demoFixturePath('missing_file.DTA'), "auto");
    assertStatusFields(missingStatus);
    assert(isempty(missingItem), 'Missing file load should not return an item.');
    assert(~missingStatus.ok, 'Missing file load should return failed status.');
    assert(contains(missingStatus.message, 'File not found'), 'Missing file status should be readable.');

    [items, report] = gamrywb.dta.loadFiles({chronoFile, eisFile, cvctFile}, "auto");
    assertLoadFilesReportFields(report);
    assert(numel(items) == 3, 'Batch auto-load should return all valid items.');
    assert(report.nRequested == 3 && report.nLoaded == 3 && report.nFailed == 0, ...
        'Batch report counts should match successful loads.');
    assert(all([report.statuses.ok]), 'Batch statuses should be successful.');

    [emptyItems, emptyReport] = gamrywb.dta.loadFiles([], "auto");
    assertLoadFilesReportFields(emptyReport);
    assert(isempty(emptyItems), 'Empty DTA batch load should return no items.');
    assert(emptyReport.nRequested == 0 && emptyReport.nLoaded == 0 && emptyReport.nFailed == 0, ...
        'Empty DTA batch report counts should be zero.');
    assert(isempty(emptyReport.loaded) && isempty(emptyReport.failed) && isempty(emptyReport.statuses), ...
        'Empty DTA batch report should have no loaded, failed, or status entries.');

    [folderItems, folderReport] = gamrywb.dta.loadFolder(demoDir, "auto");
    assertLoadFolderReportFields(folderReport);
    assert(numel(folderItems) == folderReport.nLoaded, ...
        'Folder load should return one item per successful load.');
    assert(folderReport.nDiscovered == numel(folderReport.filepaths), ...
        'Folder load report should expose discovered file count.');
    assert(folderReport.nRequested == folderReport.nDiscovered, ...
        'Folder load should request every discovered DTA file.');
    assert(strcmp(folderReport.folder, demoDir), ...
        'Folder load report should preserve the requested folder.');

    emptyDir = tempname;
    mkdir(emptyDir);
    cleaner = onCleanup(@() removeFolderIfExists(emptyDir));
    [emptyFolderItems, emptyFolderReport] = gamrywb.dta.loadFolder(emptyDir, "auto");
    assertLoadFolderReportFields(emptyFolderReport);
    assert(isempty(emptyFolderItems), 'Empty DTA folder load should return no items.');
    assert(emptyFolderReport.nDiscovered == 0 && emptyFolderReport.nRequested == 0, ...
        'Empty DTA folder report should have zero discovered and requested files.');
    assert(emptyFolderReport.nLoaded == 0 && emptyFolderReport.nFailed == 0, ...
        'Empty DTA folder report should have zero loaded and failed files.');
    assert(isempty(emptyFolderReport.filepaths), 'Empty DTA folder report should preserve an empty filepath list.');
end

function assertStatusFields(status)
    expectedFields = {'ok', 'message', 'kind', 'expectedKind', 'filepath'};
    assert(isequal(fieldnames(status), expectedFields(:)), ...
        'DTA load status fields should match the documented schema.');
end

function assertLoadFilesReportFields(report)
    expectedFields = {'loaded', 'failed', 'statuses', 'nRequested', 'nLoaded', 'nFailed'};
    assert(isequal(fieldnames(report), expectedFields(:)), ...
        'DTA batch-load report fields should match the documented schema.');
    if ~isempty(report.statuses)
        assertStatusFields(report.statuses(1));
    end
end

function assertLoadFolderReportFields(report)
    expectedFields = {'loaded', 'failed', 'statuses', 'nRequested', 'nLoaded', ...
        'nFailed', 'folder', 'filepaths', 'nDiscovered'};
    assert(isequal(fieldnames(report), expectedFields(:)), ...
        'DTA folder-load report fields should match the documented schema.');
    assertLoadFilesReportFields(rmfield(report, {'folder', 'filepaths', 'nDiscovered'}));
end

function assertInvalidFolderInput()
    try
        gamrywb.dta.findFiles(42);
    catch ME
        assert(strcmp(ME.identifier, 'gamrywb:dta:InvalidFolder'), ...
            'Invalid DTA discovery folder input should use the documented error identifier.');
        return;
    end

    error('DTA discovery should reject non-path folder input.');
end

function removeFolderIfExists(folder)
    if exist(folder, 'dir') == 7
        rmdir(folder);
    end
end
