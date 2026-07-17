classdef VtResistanceExportTest < matlab.unittest.TestCase
    %VTRESISTANCEEXPORTTEST Verify LabKit behavior through official MATLAB tests.

    methods (Test, TestTags = {'Unit'})
        function test_vtResistanceExport(testCase)
            setupLabKitTestPath();
            verify_vtResistanceExport();
        end
    end
end

function verify_vtResistanceExport()
%TEST_VTRESISTANCEEXPORT Verify VT resistance result/export table helpers.

    item = makeChronoFixtureItem('', 'chrono "vt".DTA');
    item.analysis = computeVTResistance(item, struct());
    assert(item.analysis.ok, item.analysis.message);

    definition = vt_resistance.definition();
    assert(definition.contractVersion == 2 && ...
        definition.project.Version == 1 && ...
        isempty(definition.project.Migrate), ...
        'VT Resistance should use a first-version Runtime V2 project.');
    project = definition.project.Create();
    assert(definition.project.Validate(project) && ...
        ~isfield(project.inputs, 'items'), ...
        'VT Resistance should not persist decoded DTA items.');
    session = definition.createSession(project);
    assert(session.selection.currentIndex == 0 && ...
        isempty(session.cache.items), ...
        'An empty project should rebuild an empty transient session.');

    failed = struct();
    failed.filepath = 'failed.DTA';
    failed.name = 'failed "file".DTA';
    failed.meta = [];
    failed.tables = [];
    failed.analysis = struct('ok', false, 'message', 'bad "msg"');

    items = [item failed];
    T = buildVTResultsTable(items);
    expectedNames = {'File', 'Ic_A', 'Ia_A', 'Vc_ss_V', 'Va_ss_V', ...
        'Vc_baseline_V', 'Va_baseline_V', 'dVc_V', 'dVa_V', 'Rc_bc_ohm', ...
        'Ra_bc_ohm', 'Ravg_bc_ohm', 'WindowMode', 'Detection', 'Status'};
    assert(isequal(T.Properties.VariableNames, expectedNames), ...
        'VT resistance export table headers should preserve stable CSV names.');
    assert(strcmp(T.File{1}, item.name), 'File name should be preserved.');
    assertClose(T.Ic_A(1), item.analysis.Ic_est_A, 1e-15, 'Ic export value');
    assertClose(T.Rc_bc_ohm(1), abs(item.analysis.Rc_dV_ohm), 1e-12, 'Baseline-corrected Rc export value');
    assert(strcmp(T.WindowMode{1}, item.analysis.windowMode), 'Window mode should be preserved.');
    assert(strcmp(T.Detection{1}, item.analysis.detectMode), 'Detection mode should be preserved.');
    assert(strcmp(T.Status{1}, item.analysis.message), 'Status should be preserved.');

    assert(isnan(T.Ic_A(2)) && isnan(T.Ravg_bc_ohm(2)), 'Failed rows should use NaN numeric values.');
    assert(strcmp(T.WindowMode{2}, ''), 'Failed rows should preserve stable blank window mode.');
    assert(strcmp(T.Detection{2}, 'failed'), 'Failed rows should preserve stable failed detection label.');
    assert(strcmp(T.Status{2}, failed.analysis.message), 'Failed row status should preserve analysis message.');

    C = buildVTBatchTableData(items);
    assert(isequal(size(C), [2 9]), 'VT batch UI table should preserve stable 9-column shape.');
    assert(strcmp(C{1, 1}, item.name), 'VT batch UI table should preserve item name.');
    assertClose(C{1, 6}, item.analysis.Rc_abs_ohm, 1e-12, 'VT batch UI table Rc value');
    assert(strcmp(C{1, 9}, item.analysis.detectMode), 'VT batch UI table detection value');
    assert(strcmp(C{2, 9}, 'parse/analyze failed'), 'VT batch UI table should preserve failure label.');

    tmp = [tempname '.csv'];
    cleaner = onCleanup(@() deleteIfExists(tmp));
    writeVTResultsCSV(items, tmp);
    txt = fileread(tmp);
    header = 'File,Ic_A,Ia_A,Vc_ss_V,Va_ss_V,Vc_baseline_V,Va_baseline_V,dVc_V,dVa_V,Rc_bc_ohm,Ra_bc_ohm,Ravg_bc_ohm,WindowMode,Detection,Status';
    assert(startsWith(string(txt), header), 'VT CSV header should preserve stable spelling and order.');
    assert(contains(string(txt), '"chrono ""vt"".DTA"'), 'VT CSV should preserve stable quoted file escaping.');
    assert(contains(string(txt), '"metadata-current","OK"'), 'VT CSV should preserve detection/status fields.');
    assert(contains(string(txt), '"failed ""file"".DTA",NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,"","failed","bad ""msg"""'), ...
        'VT CSV failed rows should preserve stable NaN and quoted text formatting.');
end

function deleteIfExists(filepath)
    if exist(filepath, 'file') == 2
        delete(filepath);
    end
end

function A = computeVTResistance(item, opts)
    A = vt_resistance.analysisRun.computeResistance(item, opts);
end

function T = buildVTResultsTable(items)
    T = vt_resistance.resultFiles.buildResultsTable(items);
end

function C = buildVTBatchTableData(items)
    C = vt_resistance.userInterface.buildBatchTableData(items);
end

function writeVTResultsCSV(items, filepath)
    vt_resistance.resultFiles.writeResultsCSV(items, filepath);
end
