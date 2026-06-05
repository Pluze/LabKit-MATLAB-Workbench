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

    root = testRepoRoot();
    fixture = dtaFixturePath('eis_potentiostatic_zcurve.DTA');

    [item, status] = labkit.dta.loadFile(fixture, "eis");
    assert(status.ok, status.message);
    assert(strcmp(item.type, "eis"), 'EIS item type should be normalized.');
    assert(strcmp(item.name, 'eis_potentiostatic_zcurve.DTA'), 'EIS item name should use fixture file name.');
    assert(strcmp(item.message, 'Using table: ZCURVE'), 'EIS item message should preserve ZCURVE selection wording.');
    assert(isequal(item.zcurve, item.curve), 'EIS item should expose a normalized zcurve alias.');
    assert(numel(item.Freq) == item.n, 'EIS item n should match filtered data length.');
    assert(abs(item.Freq(1) - 0.999041) < 1e-12, 'EIS item Freq should match fixture.');
    assert(abs(item.Zreal(1) - 138.7798) < 1e-12, 'EIS item Zreal should match fixture.');
    assert(abs(item.negZimag(1) - 2.786225) < 1e-12, 'EIS item negZimag should be derived from Zimag.');
    assert(~item.freqDesc, 'Fixture frequency order should preserve low-to-high/mixed summary behavior.');
    assert(isstruct(item.analysis) && isempty(fieldnames(item.analysis)), ...
        'EIS item should initialize an empty analysis struct.');
    assertClose(item.point, item.Pt, 'EIS normalized point alias');
    assertClose(item.time_s, item.Time, 'EIS normalized time alias');
    assertClose(item.freq_Hz, item.Freq, 'EIS normalized frequency alias');
    assertClose(item.Zreal_ohm, item.Zreal, 'EIS normalized Zreal alias');
    assertClose(item.Zimag_ohm, item.Zimag, 'EIS normalized Zimag alias');
    assertClose(item.negZimag_ohm, item.negZimag, 'EIS normalized -Zimag alias');
    assertClose(item.Zmod_ohm, item.Zmod, 'EIS normalized Zmod alias');
    assertClose(item.Zphz_deg, item.Zphz, 'EIS normalized Zphz alias');
    assertClose(item.Idc_A, item.Idc, 'EIS normalized Idc alias');
    assertClose(item.Vdc_V, item.Vdc, 'EIS normalized Vdc alias');

    appFile = appEntryFile(root, 'labkit_EIS_app');
    source = readAppOwnedSource(appFile);
    assert(contains(source, '''Freq (Hz)''') && contains(source, '''Zreal (ohm)''') && ...
        contains(source, '''-Zimag (ohm)'''), ...
        'EIS app should preserve stable axis labels.');
    assert(contains(source, 'RowIndex') && contains(source, 'X_%s_%s') && contains(source, 'Y_%s_%s'), ...
        'EIS app should preserve stable export column naming logic.');
    assert(contains(source, 'axis(ax, ''equal'')'), ...
        'EIS app should preserve equal-axis Nyquist plot behavior.');

    zreal = eis.ops.valuesForAxis(item, 'Zreal (ohm)');
    assertClose(zreal, item.Zreal, 'EIS app axis-value hook should preserve Zreal values');
    T = eis.export.buildExportTable(item, ...
        'Zreal (ohm)', '-Zimag (ohm)', false, false);
    assert(isequal(T.Properties.VariableNames(1), {'RowIndex'}), ...
        'EIS export table hook should preserve RowIndex as the first column.');
end

function source = readAppOwnedSource(appFile)
    appDir = fileparts(appFile);
    sourceParts = {fileread(appFile)};

    privateDir = fullfile(appDir, 'private');
    if exist(privateDir, 'dir') == 7
        fileEntries = dir(fullfile(privateDir, '*.m'));
        fileNames = sort({fileEntries.name});
        for iFile = 1:numel(fileNames)
            sourceParts{end+1} = fileread(fullfile(privateDir, fileNames{iFile})); %#ok<AGROW>
        end
    end

    packageEntries = dir(fullfile(appDir, '+*'));
    packageDirs = packageEntries([packageEntries.isdir]);
    for iDir = 1:numel(packageDirs)
        packageDir = fullfile(packageDirs(iDir).folder, packageDirs(iDir).name);
        fileEntries = dir(fullfile(packageDir, '**', '*.m'));
        filePaths = sort(fullfile({fileEntries.folder}, {fileEntries.name}));
        for iFile = 1:numel(filePaths)
            sourceParts{end+1} = fileread(filePaths{iFile}); %#ok<AGROW>
        end
    end

    source = strjoin(sourceParts, newline);
end
