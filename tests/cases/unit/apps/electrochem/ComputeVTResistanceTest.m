classdef ComputeVTResistanceTest < matlab.unittest.TestCase
    %COMPUTEVTRESISTANCETEST Verify LabKit behavior through official MATLAB tests.

    methods (Test, TestTags = {'Unit'})
        function test_computeVTResistance(testCase)
            setupLabKitTestPath();
            verify_computeVTResistance();
        end
    end
end

function verify_computeVTResistance()
%TEST_COMPUTEVTRESISTANCE Verify VT resistance app analysis.

    item = makeChronoFixtureItem();

    opts = struct();
    choices = vt_resistance.userInterface.analysisChoices();
    opts.windowMode = choices.steadyWindows(1);
    opts.voltageMode = choices.voltageModes(1);
    opts.pulseMode = choices.pulseModes(1);

    A = computeVTResistance(item, opts);
    assert(A.ok, A.message);
    assert(strcmp(A.message, 'OK'), 'Successful VT resistance result should preserve stable OK status.');
    assert(strcmp(A.windowMode, opts.windowMode), 'Window mode should be echoed in the result.');
    assert(strcmp(A.voltageMode, opts.voltageMode), 'Voltage mode should be echoed in the result.');
    assert(strcmp(A.detectMode, 'metadata-current'), 'Default fixture should use metadata-current detection.');
    assertClose(A.Ic_est_A, -0.01, 1e-12, 'Ic estimate');
    assertClose(A.Ia_est_A, 0.01, 1e-12, 'Ia estimate');
    assertClose(A.Vc_ss_V, -1, 1e-12, 'Cathodic steady voltage');
    assertClose(A.Va_ss_V, 1, 1e-12, 'Anodic steady voltage');
    assertClose(A.Vc_baseline_V, 0, 1e-12, 'Cathodic baseline');
    assertClose(A.Va_baseline_V, 0, 1e-12, 'Anodic baseline');
    assertClose(A.dVc_V, -1, 1e-12, 'Cathodic dV');
    assertClose(A.dVa_V, 1, 1e-12, 'Anodic dV');
    assertClose(A.Rc_raw_ohm, 100, 1e-10, 'Raw cathodic resistance');
    assertClose(A.Ra_raw_ohm, 100, 1e-10, 'Raw anodic resistance');
    assertClose(A.Rc_dV_ohm, 100, 1e-10, 'Baseline-corrected cathodic resistance');
    assertClose(A.Ra_dV_ohm, 100, 1e-10, 'Baseline-corrected anodic resistance');
    assertClose(A.Ravg_abs_ohm, 100, 1e-10, 'Average resistance');
    assertClose(A.cathBaselineWindow_s, 1, 1e-15, 'Cathodic baseline window');

    opts.windowMode = choices.steadyWindows(2);
    B = computeVTResistance(item, opts);
    assert(B.ok, B.message);
    assertClose(B.cathSteadyStart, A.pulse.cath_start + 0.20 * (A.pulse.cath_end - A.pulse.cath_start), ...
        1e-15, 'Center-window cathodic start');
    assertClose(B.cathSteadyEnd, A.pulse.cath_start + 0.80 * (A.pulse.cath_end - A.pulse.cath_start), ...
        1e-15, 'Center-window cathodic end');
    assertClose(B.Vc_ss_V, -1, 1e-12, 'Center-window cathodic steady voltage');
    assertClose(B.Ravg_abs_ohm, 100, 1e-10, 'Center-window average resistance');

    opts.windowMode = choices.steadyWindows(1);
    opts.voltageMode = choices.voltageModes(2);
    C = computeVTResistance(item, opts);
    assert(C.ok, C.message);
    assertClose(C.Rc_abs_ohm, 100, 1e-10, 'Raw-mode cathodic resistance');
    assertClose(C.Ra_abs_ohm, 100, 1e-10, 'Raw-mode anodic resistance');
    assertClose(C.Ravg_abs_ohm, 100, 1e-10, 'Raw-mode average resistance');

    batch = [item item];
    batch(1).analysis = struct('ok', false);
    batch(2).analysis = struct('ok', false);
    batch = vt_resistance.analysisRun.recomputeItems(batch, opts);
    analyses = [batch.analysis];
    assert(all([analyses.ok]), ...
        'Shared VT resistance settings should recompute every loaded item.');
    assert(all(string({analyses.voltageMode}) == string(opts.voltageMode)), ...
        'Every recomputed resistance item should use the same voltage mode.');

    bad = struct('meta', struct(), 'tables', struct([]));
    D = computeVTResistance(bad, struct());
    assert(~D.ok, 'Missing curve should fail.');
    assert(strcmp(D.message, 'Main transient table not found.'), 'Missing curve message should match stable wording.');

end

function A = computeVTResistance(item, opts)
    A = vt_resistance.analysisRun.computeResistance(item, opts);
end
