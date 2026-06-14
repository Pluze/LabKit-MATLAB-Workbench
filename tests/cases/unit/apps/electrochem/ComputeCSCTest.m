classdef ComputeCSCTest < matlab.unittest.TestCase
    %COMPUTECSCTEST Verify LabKit behavior through official MATLAB tests.

    methods (Test, TestTags = {'Unit'})
        function test_computeCSC(testCase)
            setupLabKitTestPath();
            verify_computeCSC();
        end
    end
end

function verify_computeCSC()
%TEST_COMPUTECSC Verify CV/CT charge and CSC app analysis.

    fixture = dtaFixturePath('cv_cyclic_voltammetry_pt_reference.DTA');

    [item, status] = labkit.dta.loadFile(fixture, "cvct");
    assert(status.ok, status.message);
    scanRate = item.scanRate;
    curves = item.curves;
    assert(~isempty(curves), 'CV/CT fixture should contain at least one curve.');
    curve = curves(1);

    opts = struct('scanRate', scanRate, 'mode', 'Full', 'area_cm2', '2');
    A = computeCSC(curve, opts);
    assert(A.ok, A.message);
    assert(strcmp(A.message, 'OK'), 'Successful CSC result should preserve OK status.');
    assert(strcmp(A.mode, 'Full'), 'Full mode should be echoed in the result.');
    assertClose(A.Qct, 0.0015, 1e-16, 'Full CT charge');
    assertClose(A.Qcv, 0.0075, 1e-16, 'Full CV charge');
    assertClose(A.diff_C, -0.006, 1e-18, 'Full charge difference');
    assertClose(A.rel_pct, 80, 1e-12, 'Full relative difference');
    assertClose(A.dtErr, 4, 1e-15, 'Full max dt error');
    assertClose(A.Qct_mC_cm2, 0.75, 1e-13, 'Full CT CSC');
    assertClose(A.Qcv_mC_cm2, 3.75, 1e-13, 'Full CV CSC');
    assert(numel(A.IcathDisp) == numel(A.Im), 'Cathodic trim vector should match filtered data length.');
    assert(numel(A.IanodDisp) == numel(A.Im), 'Anodic trim vector should match filtered data length.');

    opts.mode = 'Cathodic';
    B = computeCSC(curve, opts);
    assert(B.ok, B.message);
    assertClose(B.Qct, 0.00025, 1e-16, 'Cathodic CT charge');
    assertClose(B.Qcv, 0.00125, 1e-16, 'Cathodic CV charge');
    assertClose(B.rel_pct, 80, 1e-12, 'Cathodic relative difference');
    assertClose(B.Qct_mC_cm2, 0.125, 1e-13, 'Cathodic CSC');

    opts.mode = 'Anodic';
    C = computeCSC(curve, opts);
    assert(C.ok, C.message);
    assertClose(C.Qct, 0.00125, 1e-16, 'Anodic CT charge');
    assertClose(C.Qcv, 0.00625, 1e-16, 'Anodic CV charge');
    assertClose(C.diff_C, -0.005, 1e-18, 'Anodic charge difference');
    assertClose(C.rel_pct, 80, 1e-12, 'Anodic relative difference');

    synthetic = struct();
    synthetic.headers = {'T', 'Vf', 'Im'};
    synthetic.data = [0 0 -1; 1 1 1; 2 2 1];
    Z = computeCSC(synthetic, struct('scanRate', 2, 'mode', 'Full'));
    assert(Z.ok, 'Synthetic zero-crossing case should compute.');
    assertClose(Z.QctCath, 0.25, 1e-15, 'Synthetic CT cathodic charge');
    assertClose(Z.QctAnod, 1.25, 1e-15, 'Synthetic CT anodic charge');
    assertClose(Z.QctFull, 1.5, 1e-15, 'Synthetic CT full charge');
    assertClose(Z.QcvCath, 0.125, 1e-15, 'Synthetic CV cathodic charge');
    assertClose(Z.QcvAnod, 0.625, 1e-15, 'Synthetic CV anodic charge');
    assertClose(Z.QcvFull, 0.75, 1e-15, 'Synthetic CV full charge');
    assertClose(Z.dtErr, 0.5, 1e-15, 'Synthetic CV dt error');

    D = computeCSC(curve, struct('scanRate', NaN));
    assert(~D.ok, 'Missing scan rate should fail.');
    assert(strcmp(D.message, 'scan rate missing'), 'Missing scan-rate message should match stable UI text.');

    missingCurve = rmfield(curve, 'headers');
    E = computeCSC(missingCurve, struct('scanRate', scanRate));
    assert(~E.ok, 'Missing required columns should fail.');
    assert(strcmp(E.message, 'Need T, Vf, Im'), 'Missing-column message should match stable UI text.');

    shortCurve = curve;
    shortCurve.data = shortCurve.data(1, :);
    F = computeCSC(shortCurve, struct('scanRate', scanRate));
    assert(~F.ok, 'Single-point curve should fail.');
    assert(strcmp(F.message, 'Not enough points'), 'Single-point message should match stable UI text.');

    expectedFields = {'ok', 'message', 'mode', 'scanRate', 'area_cm2', 't', 'Vf', 'Im', ...
        'QctCath', 'QctAnod', 'QctFull', 'QcvCath', 'QcvAnod', 'QcvFull', ...
        'Qct', 'Qcv', 'diff_C', 'rel_pct', 'dtErr', ...
        'Qct_mC_cm2', 'Qcv_mC_cm2', 'diff_mC_cm2'};
    for k = 1:numel(expectedFields)
        assert(isfield(A, expectedFields{k}), ['CSC result should include field: ' expectedFields{k}]);
    end

end

function A = computeCSC(curve, opts)
    A = csc.ops.computeCSC(curve, opts);
end
