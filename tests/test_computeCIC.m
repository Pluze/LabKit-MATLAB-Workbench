function test_computeCIC()
%TEST_COMPUTECIC Verify app-side CIC / voltage-transient analysis.

    root = fileparts(fileparts(mfilename('fullpath')));
    fixture = fullfile(root, 'demo', 'chrono_chronopot_current_pulse_0p2ms.DTA');

    item = struct();
    item.filepath = fixture;
    item.name = 'chrono_chronopot_current_pulse_0p2ms.DTA';
    [item.meta, item.tables] = gamrywb.io.parseChronoDTA(fixture);

    opts = struct();
    opts.delay_s = 10e-6;
    opts.cathLimit = -0.6;
    opts.anodLimit = 0.8;
    opts.areaOverride = '';
    opts.pulseMode = 'Metadata first, then auto';
    opts.usedMeasuredCurrent = true;

    A = gamrywb_apps.cic.computeCIC(item, opts);
    assert(A.ok, A.message);
    assert(strcmp(A.message, 'OK'), 'Successful CIC result should preserve legacy OK status.');
    assert(strcmp(A.detectMode, 'metadata-current'), 'Default fixture should use metadata-current detection.');
    assertClose(A.delay_s, 10e-6, 1e-15, 'Delay');
    assertClose(A.area_cm2, 1, 1e-15, 'Metadata area');
    assertClose(A.Emc, -0.61286699999999217, 1e-12, 'Emc');
    assertClose(A.Ema, 0.59623299999998414, 1e-12, 'Ema');
    assertClose(A.Epre, -0.0029674200000000001, 1e-12, 'Pre-pulse baseline');
    assertClose(A.Ebetween, -0.183117, 1e-12, 'Interpulse baseline');
    assertClose(A.Epost, -0.00176742, 1e-12, 'Post-pulse baseline');
    assertClose(A.Eipp, -0.0029674200000000001, 1e-12, 'Cathodic baseline selection');
    assertClose(A.Eipp_gap, -0.183117, 1e-12, 'Anodic baseline selection');
    assert(strcmp(A.baselineCathSource, 'pre-pulse median'), 'Cathodic baseline source should match legacy selection.');
    assert(strcmp(A.baselineAnodSource, 'interpulse median'), 'Anodic baseline source should match legacy selection.');
    assertClose(A.Vc_on, -0.613367, 1e-12, 'Cathodic onset voltage');
    assertClose(A.Va_on, 0.57073300000000815, 1e-12, 'Anodic onset voltage');
    assertClose(A.Va_cath_mag, 0.61039957999999994, 1e-12, 'Cathodic access voltage magnitude');
    assertClose(A.Va_anod_mag, 0.75385000000000812, 1e-12, 'Anodic access voltage magnitude');
    assertClose(A.Qc_C, 2.2700154949999982e-06, 1e-18, 'Measured cathodic charge');
    assertClose(A.Qa_C, 2.2330635500000004e-06, 1e-18, 'Measured anodic charge');
    assertClose(A.Qt_C, 4.5030790449999986e-06, 1e-18, 'Measured total charge');
    assertClose(A.CICc_mCcm2, 0.0022700154949999982, 1e-15, 'Cathodic CIC');
    assertClose(A.CICt_mCcm2, 0.0045030790449999986, 1e-15, 'Total CIC');
    assert(~A.cathOK && A.anodOK && ~A.safe, 'Default water-window safety should match legacy result.');
    assert(strcmp(A.limitSide, 'cathodic exceeded'), 'Default safety side should match legacy wording.');

    opts.usedMeasuredCurrent = false;
    B = gamrywb_apps.cic.computeCIC(item, opts);
    assert(B.ok, B.message);
    assertClose(B.Qc_C, 2.4400000000000012e-06, 1e-18, 'Nominal cathodic charge');
    assertClose(B.Qa_C, 2.4400000000000012e-06, 1e-18, 'Nominal anodic charge');
    assertClose(B.Qt_C, 4.8800000000000024e-06, 1e-18, 'Nominal total charge');

    opts.usedMeasuredCurrent = true;
    opts.areaOverride = '2';
    C = gamrywb_apps.cic.computeCIC(item, opts);
    assert(C.ok, C.message);
    assertClose(C.area_cm2, 2, 1e-15, 'Area override');
    assertClose(C.CICc_mCcm2, 0.0011350077474999991, 1e-15, 'Area-normalized cathodic CIC');
    assertClose(C.CICt_mCcm2, 0.0022515395224999993, 1e-15, 'Area-normalized total CIC');

    opts.cathLimit = -2;
    opts.anodLimit = 2;
    D = gamrywb_apps.cic.computeCIC(item, opts);
    assert(D.cathOK && D.anodOK && D.safe, 'Relaxed water window should be safe.');
    assert(strcmp(D.limitSide, 'safe'), 'Safe status text should match legacy wording.');

    bad = struct('meta', struct(), 'tables', struct([]));
    E = gamrywb_apps.cic.computeCIC(bad, struct());
    assert(~E.ok, 'Missing curve should fail.');
    assert(strcmp(E.message, 'Main transient table not found.'), 'Missing curve message should match legacy wording.');
end

function assertClose(actual, expected, tol, label)
    assert(abs(actual - expected) < tol, '%s should match expected value.', label);
end
