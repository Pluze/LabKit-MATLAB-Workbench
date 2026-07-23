classdef EisOverlayExportTest < matlab.unittest.TestCase
    %EISOVERLAYEXPORTTEST Verify LabKit behavior through official MATLAB tests.

    methods (Test, TestTags = {'Unit'})
        function test_eisOverlayExport(testCase)
            setupLabKitTestPath();
            verify_eisOverlayExport();
        end
    end
end

function verify_eisOverlayExport()
%TEST_EISOVERLAYEXPORT Verify EIS item schema and export/plot contracts.

    fixture = dtaFixturePath('eis_potentiostatic_zcurve.DTA');

    [item, status] = labkit.dta.loadFile(fixture, "eis");
    assert(status.ok, status.message);
    assert(strcmp(item.type, "eis"), 'EIS item type should be normalized.');
    assert(strcmp(item.name, 'eis_potentiostatic_zcurve.DTA'), 'EIS item name should use fixture file name.');
    assert(strcmp(item.message, 'Using table: ZCURVE'), 'EIS item message should preserve ZCURVE selection wording.');
    assert(isequal(item.zcurve, item.curve), 'EIS item should expose a normalized zcurve alias.');
    assert(numel(item.freq_Hz) == item.n, 'EIS item n should match filtered data length.');
    assert(abs(item.freq_Hz(1) - 0.999041) < 1e-12, 'EIS item frequency should match fixture.');
    assert(abs(item.Zreal_ohm(1) - 138.7798) < 1e-12, 'EIS item real impedance should match fixture.');
    assert(abs(item.negZimag_ohm(1) - 2.786225) < 1e-12, 'EIS item negative imaginary impedance should be derived.');
    assert(~item.freqDesc, 'Fixture frequency order should preserve low-to-high/mixed summary behavior.');
    assert(isstruct(item.analysis) && isempty(fieldnames(item.analysis)), ...
        'EIS item should initialize an empty analysis struct.');
    axisItems = eis.overlayPlot.axisItems();

    definition = eis.definition();
    schema = definition.ProjectSchema;
    assert(isa(definition, "labkit.app.Definition") && ...
        schema.Version == 1 && isempty(schema.Migrate), ...
        'EIS should use a first-version App SDK project contract.');
    project = schema.Create();
    assert(schema.Validate(project) && ...
        ~isfield(project.inputs, 'items'), ...
        'EIS projects should validate without decoded DTA items.');
    runtime = labkit.app.internal.RuntimeFactory.createHeadless(definition);
    cleanup = onCleanup(@() runtime.close());
    runtime.applyFileSelection("files", string(fixture), 1);
    state = runtime.State;
    assert(numel(state.session.cache.items) == 1 && ...
        state.session.selection.files.Indices == 1 && ...
        all(ismember(["files", "plot"], ...
            labkit.app.internal.DefinitionInspector.targetIds(definition))), ...
        'EIS runtime should prepare its overlay and source selection.');
    assert(~contains(evalc('disp(state)'), 'matlab.ui'), ...
        'EIS canonical state should contain no UI handles.');

    canonicalItem = removeLegacyEisFields(item);
    zreal = eis.analysisRun.valuesForAxis(canonicalItem, axisItems(5));
    assertClose(zreal, item.Zreal_ohm, 'EIS app axis-value hook should preserve Zreal values');
    logFreq = eis.analysisRun.valuesForAxis(canonicalItem, axisItems(2));
    assertClose(logFreq, log10(item.freq_Hz), 'EIS app log-frequency axis values');

    T = eis.resultFiles.buildExportTable(canonicalItem, ...
        axisItems(5), axisItems(7), false, false);
    assert(isequal(T.Properties.VariableNames(1), {'RowIndex'}), ...
        'EIS export table hook should preserve RowIndex as the first column.');
    expectedX = matlab.lang.makeValidName(sprintf('X_%s_%s', ...
        'zreal_ohm', matlab.lang.makeValidName(item.name)));
    expectedY = matlab.lang.makeValidName(sprintf('Y_%s_%s', ...
        'zimag_ohm', matlab.lang.makeValidName(item.name)));
    assert(any(strcmp(T.Properties.VariableNames, expectedX)), ...
        'EIS export table should preserve axis/file-based X column names.');
    assert(any(strcmp(T.Properties.VariableNames, expectedY)), ...
        'EIS export table should preserve axis/file-based Y column names.');

    summary = eis.sourceFiles.buildSummary(canonicalItem);
    assert(numel(summary) == 2 && contains(summary{2}, item.name) && ...
        contains(summary{2}, sprintf('N=%d', item.n)) && ...
        contains(summary{2}, 'Freq') && contains(summary{2}, 'Hz') && ...
        contains(summary{2}, 'low->high/mixed'), ...
        'EIS summary should report canonical item details.');

    clear cleanup;
end

function item = removeLegacyEisFields(item)
    legacyFields = {'Pt', 'Time', 'Freq', 'Zreal', 'Zimag', 'negZimag', ...
        'Zmod', 'Zphz', 'Idc', 'Vdc'};
    present = legacyFields(isfield(item, legacyFields));
    if ~isempty(present)
        item = rmfield(item, present);
    end
end
