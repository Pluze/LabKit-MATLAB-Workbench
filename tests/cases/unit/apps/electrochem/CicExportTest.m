classdef CicExportTest < matlab.unittest.TestCase
    %CICEXPORTTEST Verify LabKit behavior through official MATLAB tests.

    methods (Test, TestTags = {'Unit'})
        function test_cicExport(testCase)
            setupLabKitTestPath();
            verify_cicExport();
        end
    end
end

function verify_cicExport()
%TEST_CICEXPORT Verify app-side CIC result/export table helpers.

    item = makeChronoFixtureItem('', 'chrono "cic".DTA');
    choices = cic.userInterface.analysisChoices();

    opts = struct();
    opts.delay_s = 10e-6;
    opts.cathLimit = -0.6;
    opts.anodLimit = 0.8;
    opts.areaOverride = '';
    opts.pulseMode = char(choices.pulseModes(1));
    opts.usedMeasuredCurrent = true;
    item.analysis = computeCIC(item, opts);
    assert(item.analysis.ok, item.analysis.message);

    definition = cic.definition();
    assert(definition.contractVersion == 2 && ...
        definition.project.Version == 1 && ...
        isempty(definition.project.Migrations), ...
        'CIC should use a first-version Runtime V2 project contract.');
    project = definition.project.Create();
    assert(definition.project.Validate(project) && ...
        ~isfield(project.inputs, 'items'), ...
        'CIC projects should validate without persisting decoded DTA items.');
    session = definition.createSession(project);
    [~, sourceName, sourceExtension] = fileparts(item.filepath);
    reference = struct( ...
        "schemaVersion", 1, "relativePath", "", ...
        "originalPath", string(item.filepath), ...
        "fileName", string(sourceName) + string(sourceExtension));
    project.inputs.sources = struct( ...
        "id", "item1", "required", true, "role", "chrono", ...
        "reference", reference);
    session.cache.items = item;
    session.selection.currentIndex = 1;
    state = struct("project", project, "session", session);
    presentation = definition.present(state);
    assert(isfield(presentation.previews.plotAxes.Axes, 'top') && ...
        isfield(presentation.previews.plotAxes.Axes, 'bottom') && ...
        string(presentation.controls.files.Selection) == "item1", ...
        'CIC presenter should prepare both axes and current source selection.');
    assert(~contains(evalc('disp(state)'), 'matlab.ui'), ...
        'CIC canonical state should contain no UI handles.');

    failed = struct();
    failed.filepath = 'failed.DTA';
    failed.name = 'failed "file".DTA';
    failed.meta = [];
    failed.tables = [];
    failed.analysis = struct('ok', false, 'message', 'bad "msg"');

    items = [item failed];

    T = buildCICResultsTable(items, 'mC/cm^2');
    expectedNames = {'File', 'Amp_A', 'Emc_V', 'Ema_V', 'Qc_C', 'Qa_C', 'Qt_C', ...
        'CICc_mCcm2', 'CICa_mCcm2', 'CICt_mCcm2', 'Safe', 'Detection', ...
        'Area_cm2', 'Delay_us'};
    assert(isequal(T.Properties.VariableNames, expectedNames), ...
        'CIC export table headers should preserve stable mC CSV names.');
    assertClose(T.Amp_A(1), item.analysis.ampEstimate_A, 1e-15, 'CIC amp export value');
    assertClose(T.CICc_mCcm2(1), item.analysis.CICc_mCcm2, 1e-15, 'CIC mC cathodic value');
    assert(T.Safe(1) == item.analysis.safe, 'CIC safe flag should be preserved.');
    assert(strcmp(T.Detection{1}, item.analysis.detectMode), 'CIC detection mode should be preserved.');
    assertClose(T.Area_cm2(1), item.analysis.area_cm2, 1e-15, 'CIC area audit value');
    assertClose(T.Delay_us(1), 10, 1e-12, 'CIC delay audit value');
    assert(isnan(T.Amp_A(2)) && isnan(T.CICt_mCcm2(2)), 'Failed CIC rows should use NaN numeric values.');
    assert(T.Safe(2) == 0, 'Failed CIC rows should preserve stable Safe=0.');
    assert(strcmp(T.Detection{2}, 'failed'), 'Failed CIC rows should preserve stable failed detection label.');

    Tu = buildCICResultsTable(item, 'uC/cm^2');
    assert(isequal(Tu.Properties.VariableNames(8:10), {'CICc_uCcm2', 'CICa_uCcm2', 'CICt_uCcm2'}), ...
        'CIC export table headers should preserve stable uC CSV names.');
    assertClose(Tu.CICc_uCcm2(1), 1e3 * item.analysis.CICc_mCcm2, 1e-12, 'CIC uC cathodic value');

    [C, cols] = buildCICBatchTableData(items, 'uC/cm^2');
    assert(isequal(cols, {'File','Amp(A)','Emc(V)','Ema(V)','Qc(uC/cm^2)','Qa(uC/cm^2)','Qtot(uC/cm^2)','Safe'}), ...
        'CIC batch UI table headers should preserve stable unit labels.');
    assert(isequal(size(C), [2 8]), 'CIC batch UI table should preserve stable 8-column shape.');
    assertClose(C{1, 5}, 1e3 * item.analysis.CICc_mCcm2, 1e-12, 'CIC batch UI scaled Qc value');
    assert(strcmp(C{1, 8}, item.analysis.limitSide), 'CIC batch UI unsafe label should preserve limit side.');
    assert(strcmp(C{2, 8}, 'parse/analyze failed'), 'CIC batch UI failed rows should preserve failure label.');

    tmp = [tempname '.csv'];
    cleaner = onCleanup(@() deleteIfExists(tmp));
    writeCICResultsCSV(items, tmp, 'mC/cm^2');
    txt = fileread(tmp);
    header = ['File,Amp_A,Emc_V,Ema_V,Qc_C,Qa_C,Qt_C,CICc_mCcm2,' ...
        'CICa_mCcm2,CICt_mCcm2,Safe,Detection,Area_cm2,Delay_us'];
    assert(startsWith(string(txt), header), 'CIC CSV header should preserve stable spelling and order.');
    assert(contains(string(txt), '"chrono "cic".DTA"'), 'CIC CSV should preserve stable unescaped quoted file text.');
    assert(contains(string(txt), '"metadata-current"'), 'CIC CSV should preserve detection field.');
    assert(contains(string(txt), '"failed "file".DTA",,,,,,,,,,0,"failed",,'), ...
        'CIC CSV failed rows should preserve stable empty fields and failed marker.');
end

function deleteIfExists(filepath)
    if exist(filepath, 'file') == 2
        delete(filepath);
    end
end

function A = computeCIC(item, opts)
    A = cic.analysisRun.computeCIC(item, opts);
end

function T = buildCICResultsTable(items, unitLabel)
    T = cic.resultFiles.buildResultsTable(items, unitLabel);
end

function [C, cols] = buildCICBatchTableData(items, unitLabel)
    [C, cols] = cic.userInterface.buildBatchTableData(items, unitLabel);
end

function writeCICResultsCSV(items, filepath, unitLabel)
    cic.resultFiles.writeResultsCSV(items, filepath, unitLabel);
end
