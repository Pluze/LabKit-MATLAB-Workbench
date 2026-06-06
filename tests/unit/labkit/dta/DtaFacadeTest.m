classdef DtaFacadeTest < matlab.unittest.TestCase
    %DTAFACADETEST Verify LabKit behavior through official MATLAB tests.

    methods (Test, TestTags = {'Unit'})
        function test_dtaFacade(testCase)
            setupLabKitTestPath();
            verify_dtaFacade();
        end
    end
end

function verify_dtaFacade()
%TEST_DTAFACADE Verify GUI-free DTA type detection and loading facade.

    fixtureDir = dtaFixtureDir();
    chronoFile = dtaFixturePath('chrono_chronopot_current_pulse_0p2ms.DTA');
    eisFile = dtaFixturePath('eis_potentiostatic_zcurve.DTA');
    cvctFile = dtaFixturePath('cv_cyclic_voltammetry_pt_reference.DTA');

    discoveredFiles = labkit.dta.findFiles(fixtureDir);
    assert(numel(discoveredFiles) >= 8, 'DTA facade should recursively discover DTA test fixtures.');
    assert(all(endsWith(lower(string(discoveredFiles)), '.dta')), ...
        'DTA facade discovery should return only DTA files.');
    assert(any(strcmp(discoveredFiles, chronoFile)), ...
        'DTA facade discovery should include the current-controlled chrono fixture.');
    assert(isequal(labkit.dta.findFiles(string(fixtureDir)), discoveredFiles), ...
        'DTA facade discovery should accept scalar string folders.');
    assertInvalidFolderInput(42);
    assertInvalidFolderInput(fullfile(tempdir, 'labkit_missing_dta_folder'));

    assert(labkit.dta.detectType(chronoFile) == "chrono", 'Chrono fixture should detect as chrono.');
    assert(labkit.dta.detectType(eisFile) == "eis", 'EIS fixture should detect as eis.');
    assert(labkit.dta.detectType(cvctFile) == "cvct", 'CV/CT fixture should detect as cvct.');

    [chronoItem, chronoStatus] = labkit.dta.loadFile(chronoFile, "chrono");
    assertStatusFields(chronoStatus);
    assert(chronoStatus.ok, chronoStatus.message);
    assert(chronoStatus.kind == "chrono", 'Chrono status kind should be chrono.');
    assert(chronoItem.type == "chrono", 'Chrono item type should be preserved.');
    assert(isfield(chronoItem, 't_s') && isfield(chronoItem, 'Vf_V') && isfield(chronoItem, 'Im_A'), ...
        'Chrono facade should expose canonical unit-explicit vectors.');
    [pulse, pulseMsg] = labkit.dta.detectPulses( ...
        chronoItem.t_s, chronoItem.Im_A, chronoItem.meta, "Metadata first, then auto");
    assert(pulse.ok, pulseMsg);
    assert(isfield(pulse, 'gap_start') && isfinite(pulse.gap_start), ...
        'DTA facade should expose chrono pulse detection without app code calling analysis directly.');

    [spacedKindItem, spacedKindStatus] = labkit.dta.loadFile(chronoFile, " Chrono ");
    assert(spacedKindStatus.ok, spacedKindStatus.message);
    assert(spacedKindStatus.expectedKind == "chrono" && spacedKindStatus.kind == "chrono", ...
        'DTA facade should normalize expected kind case and whitespace consistently.');
    assert(spacedKindItem.type == "chrono", 'Normalized expected kind should load the chrono item.');

    [eisItem, eisStatus] = labkit.dta.loadFile(eisFile);
    assert(eisStatus.ok, eisStatus.message);
    assert(eisStatus.kind == "eis", 'Auto-loaded EIS status kind should be eis.');
    assert(eisItem.type == "eis", 'EIS item type should be preserved.');
    assert(isfield(eisItem, 'freq_Hz') && isfield(eisItem, 'Zreal_ohm') && isfield(eisItem, 'Zimag_ohm'), ...
        'EIS facade should expose canonical unit-explicit impedance vectors.');

    [cvctItem, cvctStatus] = labkit.dta.loadFile(cvctFile, "cvct");
    assert(cvctStatus.ok, cvctStatus.message);
    assert(cvctStatus.kind == "cvct", 'CV/CT status kind should be cvct.');
    assert(cvctItem.type == "cvct", 'CV/CT item type should be set.');
    assert(~isempty(cvctItem.curves), 'CV/CT item should include parsed curves.');
    assert(isfield(cvctItem, 'scanRate') && isfield(cvctItem, 'scanRate_V_per_s'), ...
        'CV/CT item should expose scan rate fields.');

    [mismatchItem, mismatchStatus] = labkit.dta.loadFile(eisFile, "chrono");
    assertStatusFields(mismatchStatus);
    assert(isempty(mismatchItem), 'Mismatched DTA load should not return an item.');
    assert(~mismatchStatus.ok, 'Mismatched DTA load should return failed status.');
    assert(mismatchStatus.kind == "eis", 'Mismatch status should report detected kind.');
    assert(contains(mismatchStatus.message, 'Expected chrono DTA'), ...
        'Mismatch status should explain expected kind.');

    [cvctMismatchItem, cvctMismatchStatus] = labkit.dta.loadFile(cvctFile, "chrono");
    assertStatusFields(cvctMismatchStatus);
    assert(isempty(cvctMismatchItem), 'CV/CT mismatch load should not return an item.');
    assert(~cvctMismatchStatus.ok, 'CV/CT mismatch load should return failed status.');
    assert(cvctMismatchStatus.kind == "cvct", ...
        'CV/CT mismatch status should report the detected CV/CT kind.');
    assert(contains(cvctMismatchStatus.message, 'Expected chrono DTA'), ...
        'CV/CT mismatch status should explain expected kind.');

    [missingItem, missingStatus] = labkit.dta.loadFile(dtaFixturePath('missing_file.DTA'), "auto");
    assertStatusFields(missingStatus);
    assert(isempty(missingItem), 'Missing file load should not return an item.');
    assert(~missingStatus.ok, 'Missing file load should return failed status.');
    assert(contains(missingStatus.message, 'File not found'), 'Missing file status should be readable.');

    [items, report] = labkit.dta.loadFiles({chronoFile, eisFile, cvctFile}, "auto");
    assertLoadFilesReportFields(report);
    assert(numel(items) == 3, 'Batch auto-load should return all valid items.');
    assert(report.nRequested == 3 && report.nLoaded == 3 && report.nFailed == 0, ...
        'Batch report counts should match successful loads.');
    assert(all([report.statuses.ok]), 'Batch statuses should be successful.');

    [emptyItems, emptyReport] = labkit.dta.loadFiles([], "auto");
    assertLoadFilesReportFields(emptyReport);
    assert(isempty(emptyItems), 'Empty DTA batch load should return no items.');
    assert(emptyReport.nRequested == 0 && emptyReport.nLoaded == 0 && emptyReport.nFailed == 0, ...
        'Empty DTA batch report counts should be zero.');
    assert(isempty(emptyReport.loaded) && isempty(emptyReport.failed) && isempty(emptyReport.statuses), ...
        'Empty DTA batch report should have no loaded, failed, or status entries.');
    [blankKindItems, blankKindReport] = labkit.dta.loadFiles([], "");
    assert(isempty(blankKindItems), 'Blank expected kind should default to auto for empty DTA batch loads.');
    assert(blankKindReport.nRequested == 0 && blankKindReport.nLoaded == 0 && blankKindReport.nFailed == 0, ...
        'Blank expected kind should preserve empty DTA batch no-op report counts.');
    assertInvalidExpectedKind(@() labkit.dta.loadFiles([], "bad"));

    [folderItems, folderReport] = labkit.dta.loadFolder(fixtureDir, "auto");
    assertLoadFolderReportFields(folderReport);
    assert(numel(folderItems) == folderReport.nLoaded, ...
        'Folder load should return one item per successful load.');
    assert(folderReport.nDiscovered == numel(folderReport.filepaths), ...
        'Folder load report should expose discovered file count.');
    assert(folderReport.nRequested == folderReport.nDiscovered, ...
        'Folder load should request every discovered DTA file.');
    assert(strcmp(folderReport.folder, fixtureDir), ...
        'Folder load report should preserve the requested folder.');

    emptyDir = tempname;
    mkdir(emptyDir);
    cleaner = onCleanup(@() removeFolderIfExists(emptyDir));
    [emptyFolderItems, emptyFolderReport] = labkit.dta.loadFolder(emptyDir, "auto");
    assertLoadFolderReportFields(emptyFolderReport);
    assert(isempty(emptyFolderItems), 'Empty DTA folder load should return no items.');
    assert(emptyFolderReport.nDiscovered == 0 && emptyFolderReport.nRequested == 0, ...
        'Empty DTA folder report should have zero discovered and requested files.');
    assert(emptyFolderReport.nLoaded == 0 && emptyFolderReport.nFailed == 0, ...
        'Empty DTA folder report should have zero loaded and failed files.');
    assert(isempty(emptyFolderReport.filepaths), 'Empty DTA folder report should preserve an empty filepath list.');
    assertInvalidExpectedKind(@() labkit.dta.loadFolder(emptyDir, "bad"));
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

function assertInvalidFolderInput(folder)
    try
        labkit.dta.findFiles(folder);
    catch ME
        assert(strcmp(ME.identifier, 'labkit:dta:InvalidFolder'), ...
            'Invalid DTA discovery folder input should use the documented error identifier.');
        return;
    end

    error('DTA discovery should reject invalid folder input.');
end

function assertInvalidExpectedKind(callFcn)
    try
        callFcn();
    catch ME
        assert(strcmp(ME.identifier, 'labkit:dta:InvalidKind'), ...
            'Invalid expected DTA kind should use the documented error identifier.');
        return;
    end

    error('DTA facade should reject invalid expected DTA kind.');
end

function removeFolderIfExists(folder)
    if exist(folder, 'dir') == 7
        rmdir(folder);
    end
end
