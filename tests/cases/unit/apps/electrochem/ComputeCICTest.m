classdef ComputeCICTest < matlab.unittest.TestCase
    %COMPUTECICTEST Verify LabKit behavior through official MATLAB tests.

    methods (Test, TestTags = {'Unit'})
        function test_computeCIC(testCase)
            setupLabKitTestPath();
            verify_computeCIC();
        end
    end
end

function verify_computeCIC()
%TEST_COMPUTECIC Verify app-side CIC / voltage-transient analysis.

    item = makeChronoFixtureItem();

    opts = struct();
    opts.delay_s = 10e-6;
    opts.cathLimit = -0.6;
    opts.anodLimit = 0.8;
    opts.areaOverride = '';
    opts.pulseMode = 'Metadata first, then auto';
    opts.usedMeasuredCurrent = true;

    A = computeCIC(item, opts);
    assert(A.ok, A.message);
    assert(strcmp(A.message, 'OK'), 'Successful CIC result should preserve stable OK status.');
    assert(strcmp(A.detectMode, 'metadata-current'), 'Default fixture should use metadata-current detection.');
    assertClose(A.delay_s, 10e-6, 1e-15, 'Delay');
    assertClose(A.area_cm2, 1, 1e-15, 'Metadata area');
    assertClose(A.Emc, -0.99996, 1e-12, 'Emc');
    assertClose(A.Ema, 0.999960000000002, 1e-12, 'Ema');
    assertClose(A.Epre, 0, 1e-12, 'Pre-pulse baseline');
    assertClose(A.Ebetween, 0, 1e-12, 'Interpulse baseline');
    assertClose(A.Epost, 0, 1e-12, 'Post-pulse baseline');
    assertClose(A.Eipp, 0, 1e-12, 'Cathodic baseline selection');
    assertClose(A.Eipp_gap, 0, 1e-12, 'Anodic baseline selection');
    assert(strcmp(A.baselineCathSource, 'pre-pulse median'), 'Cathodic baseline source should match stable selection.');
    assert(strcmp(A.baselineAnodSource, 'interpulse median'), 'Anodic baseline source should match stable selection.');
    assertClose(A.Vc_on, -1, 1e-12, 'Cathodic onset voltage');
    assertClose(A.Va_on, 1, 1e-12, 'Anodic onset voltage');
    assertClose(A.Va_cath_mag, 1, 1e-12, 'Cathodic access voltage magnitude');
    assertClose(A.Va_anod_mag, 1, 1e-12, 'Anodic access voltage magnitude');
    assertClose(A.Qc_C, 0.01, 1e-15, 'Measured cathodic charge');
    assertClose(A.Qa_C, 0.01, 1e-15, 'Measured anodic charge');
    assertClose(A.Qt_C, 0.02, 1e-15, 'Measured total charge');
    assertClose(A.CICc_mCcm2, 10, 1e-12, 'Cathodic CIC');
    assertClose(A.CICt_mCcm2, 20, 1e-12, 'Total CIC');
    assert(~A.cathOK && ~A.anodOK && ~A.safe, 'Default water-window safety should match stable result.');
    assert(strcmp(A.limitSide, 'both exceeded'), 'Default safety side should match stable wording.');

    opts.usedMeasuredCurrent = false;
    B = computeCIC(item, opts);
    assert(B.ok, B.message);
    assertClose(B.Qc_C, 0.01, 1e-15, 'Nominal cathodic charge');
    assertClose(B.Qa_C, 0.01, 1e-15, 'Nominal anodic charge');
    assertClose(B.Qt_C, 0.02, 1e-15, 'Nominal total charge');

    opts.usedMeasuredCurrent = true;
    opts.areaOverride = '2';
    C = computeCIC(item, opts);
    assert(C.ok, C.message);
    assertClose(C.area_cm2, 2, 1e-15, 'Area override');
    assertClose(C.CICc_mCcm2, 5, 1e-12, 'Area-normalized cathodic CIC');
    assertClose(C.CICt_mCcm2, 10, 1e-12, 'Area-normalized total CIC');

    opts.cathLimit = -2;
    opts.anodLimit = 2;
    D = computeCIC(item, opts);
    assert(D.cathOK && D.anodOK && D.safe, 'Relaxed water window should be safe.');
    assert(strcmp(D.limitSide, 'safe'), 'Safe status text should match stable wording.');

    bad = struct('meta', struct(), 'tables', struct([]));
    E = computeCIC(bad, struct());
    assert(~E.ok, 'Missing curve should fail.');
    assert(strcmp(E.message, 'Main transient table not found.'), 'Missing curve message should match stable wording.');

end

function A = computeCIC(item, opts)
    A = cic.ops.computeCIC(item, opts);
end
