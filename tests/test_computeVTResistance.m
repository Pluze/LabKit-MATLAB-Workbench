function test_computeVTResistance()
%TEST_COMPUTEVTRESISTANCE Verify VT resistance app analysis.

    root = fileparts(fileparts(mfilename('fullpath')));
    fixture = fullfile(root, 'demo', 'chrono_chronopot_current_pulse_0p2ms.DTA');

    item = struct();
    item.filepath = fixture;
    item.name = 'chrono_chronopot_current_pulse_0p2ms.DTA';
    [item.meta, item.tables] = gamrywb.io.parseChronoDTA(fixture);

    opts = struct();
    opts.windowMode = 'Full pulse median';
    opts.voltageMode = 'Baseline-corrected dV/I';
    opts.pulseMode = 'Metadata first, then auto';

    A = gamrywb_apps.vt.computeResistance(item, opts);
    assert(A.ok, A.message);
    assert(strcmp(A.message, 'OK'), 'Successful VT resistance result should preserve legacy OK status.');
    assert(strcmp(A.windowMode, opts.windowMode), 'Window mode should be echoed in the result.');
    assert(strcmp(A.voltageMode, opts.voltageMode), 'Voltage mode should be echoed in the result.');
    assert(strcmp(A.detectMode, 'metadata-current'), 'Default fixture should use metadata-current detection.');
    assertClose(A.Ic_est_A, -0.0121306, 1e-12, 'Ic estimate');
    assertClose(A.Ia_est_A, 0.012127300000000001, 1e-12, 'Ia estimate');
    assertClose(A.Vc_ss_V, -1.2126699999999999, 1e-12, 'Cathodic steady voltage');
    assertClose(A.Va_ss_V, 1.19983, 1e-12, 'Anodic steady voltage');
    assertClose(A.Vc_baseline_V, -0.0029674200000000001, 1e-12, 'Cathodic baseline');
    assertClose(A.Va_baseline_V, -0.00176742, 1e-12, 'Anodic baseline');
    assertClose(A.dVc_V, -1.2097025799999999, 1e-12, 'Cathodic dV');
    assertClose(A.dVa_V, 1.2015974199999999, 1e-12, 'Anodic dV');
    assertClose(A.Rc_raw_ohm, 99.967849900252247, 1e-10, 'Raw cathodic resistance');
    assertClose(A.Ra_raw_ohm, 98.93628425123481, 1e-10, 'Raw anodic resistance');
    assertClose(A.Rc_dV_ohm, 99.723227210525437, 1e-10, 'Baseline-corrected cathodic resistance');
    assertClose(A.Ra_dV_ohm, 99.08202320384585, 1e-10, 'Baseline-corrected anodic resistance');
    assertClose(A.Ravg_abs_ohm, 99.40262520718565, 1e-10, 'Average resistance');
    assertClose(A.cathBaselineWindow_s, 0.001, 1e-15, 'Cathodic baseline window');

    opts.windowMode = 'Center 60% median';
    B = gamrywb_apps.vt.computeResistance(item, opts);
    assert(B.ok, B.message);
    assertClose(B.Vc_ss_V, -1.21322, 1e-12, 'Center-window cathodic steady voltage');
    assertClose(B.Ravg_abs_ohm, 99.417071968208802, 1e-10, 'Center-window average resistance');

    opts.windowMode = 'Full pulse median';
    opts.voltageMode = 'Raw Vf/I';
    C = gamrywb_apps.vt.computeResistance(item, opts);
    assert(C.ok, C.message);
    assertClose(C.Rc_abs_ohm, 99.967849900252247, 1e-10, 'Raw-mode cathodic resistance');
    assertClose(C.Ra_abs_ohm, 98.93628425123481, 1e-10, 'Raw-mode anodic resistance');
    assertClose(C.Ravg_abs_ohm, 99.452067075743528, 1e-10, 'Raw-mode average resistance');

    [c1, c2] = gamrywb_apps.vt.selectSteadyWindow(1, 2, 'Center 60% median');
    assertClose(c1, 1.2, 1e-15, 'Center-window start');
    assertClose(c2, 1.8, 1e-15, 'Center-window end');

    [baseline, window] = gamrywb_apps.vt.estimateBaseline([0; 1], [NaN; NaN], 0, 1, 5);
    assertClose(baseline, 5, 1e-15, 'Baseline fallback');
    assertClose(window, 1, 1e-15, 'Baseline window duration');

    bad = struct('meta', struct(), 'tables', struct([]));
    D = gamrywb_apps.vt.computeResistance(bad, struct());
    assert(~D.ok, 'Missing curve should fail.');
    assert(strcmp(D.message, 'Main transient table not found.'), 'Missing curve message should match legacy wording.');
end

function assertClose(actual, expected, tol, label)
    assert(abs(actual - expected) < tol, '%s should match expected value.', label);
end
