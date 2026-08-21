classdef VtResistanceScientificSpec < matlab.unittest.TestCase
    %VTRESISTANCESCIENTIFICSPEC Specify biphasic transient resistance metrics.

    methods (Test, TestTags = {'Contract:scientific', 'Env:headless'})
        function calculatesSteadyPulseResistanceWithDeclaredPolicies(testCase)
            item = testfixtures.dta.chronoItem();
            choices = vt_resistance.analysisRun.analysisChoices();
            options = struct("windowMode", choices.steadyWindows(1), ...
                "voltageMode", choices.voltageModes(1), ...
                "pulseMode", choices.pulseModes(1));

            analysis = vt_resistance.analysisRun.computeResistance(item, options);

            testCase.verifyTrue(analysis.ok, analysis.message);
            testCase.verifyEqual(string(analysis.detectMode), "metadata-current");
            testCase.verifyEqual([analysis.Ic_est_A, analysis.Ia_est_A], [-0.01, 0.01], ...
                "AbsTol", 1e-12);
            testCase.verifyEqual([analysis.Vc_ss_V, analysis.Va_ss_V], [-1, 1], ...
                "AbsTol", 1e-12);
            testCase.verifyEqual([analysis.Rc_dV_ohm, analysis.Ra_dV_ohm, ...
                analysis.Ravg_abs_ohm], [100, 100, 100], "AbsTol", 1e-10);
        end

        function recomputesSharedSettingsAndReportsInvalidCurves(testCase)
            item = testfixtures.dta.chronoItem();
            options = struct("windowMode", "Center 60% median", ...
                "voltageMode", "Raw Vf/I", "pulseMode", "Metadata only");
            items = repmat(item, 1, 2);

            items = vt_resistance.analysisRun.recomputeItems(items, options);
            invalid = vt_resistance.analysisRun.computeResistance( ...
                struct("meta", struct(), "tables", struct([])), struct());

            analyses = [items.analysis];
            testCase.verifyTrue(all([analyses.ok]));
            testCase.verifyTrue(all(string({analyses.voltageMode}) == "Raw Vf/I"));
            testCase.verifyTrue(invalid.ok == false);
            testCase.verifyEqual(string(invalid.message), "Main transient table not found.");
        end

        function centerWindowAndRawVoltagePoliciesKeepTheExpectedResistance(testCase)
            item = testfixtures.dta.chronoItem();
            choices = vt_resistance.analysisRun.analysisChoices();
            center = vt_resistance.analysisRun.computeResistance(item, struct( ...
                "windowMode", choices.steadyWindows(2), ...
                "voltageMode", choices.voltageModes(1), ...
                "pulseMode", choices.pulseModes(1)));
            raw = vt_resistance.analysisRun.computeResistance(item, struct( ...
                "windowMode", choices.steadyWindows(1), ...
                "voltageMode", choices.voltageModes(2), ...
                "pulseMode", choices.pulseModes(1)));

            testCase.verifyTrue(center.ok, center.message);
            testCase.verifyEqual(center.cathSteadyStart, ...
                center.pulse.cath.start_s + .2 * (center.pulse.cath.end_s - center.pulse.cath.start_s), ...
                AbsTol=1e-15);
            testCase.verifyEqual(center.cathSteadyEnd, ...
                center.pulse.cath.start_s + .8 * (center.pulse.cath.end_s - center.pulse.cath.start_s), ...
                AbsTol=1e-15);
            testCase.verifyEqual(center.Ravg_abs_ohm, 100, AbsTol=1e-10);
            testCase.verifyTrue(raw.ok, raw.message);
            testCase.verifyEqual([raw.Rc_abs_ohm, raw.Ra_abs_ohm, raw.Ravg_abs_ohm], ...
                [100, 100, 100], AbsTol=1e-10);
        end
    end
end
