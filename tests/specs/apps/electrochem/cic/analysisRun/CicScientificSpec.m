classdef CicScientificSpec < matlab.unittest.TestCase
    %CICSCIENTIFICSPEC Verify CIC calculations directly at their capability owner.

    methods (Test, TestTags = {'Contract:scientific', 'Env:headless'})
        function calculatesChargeAndVoltageMetrics(testCase)
            item = testfixtures.makeChronoFixtureItem();
            analysis = cic.analysisRun.computeCIC(item, defaultOptions());

            testCase.verifyTrue(analysis.ok, analysis.message);
            testCase.verifyEqual(analysis.detectMode, 'metadata-current');
            testCase.verifyEqual(analysis.area_cm2, 1, 'AbsTol', 1e-15);
            testCase.verifyEqual(analysis.Emc, -0.99996, 'AbsTol', 1e-12);
            testCase.verifyEqual(analysis.Ema, 0.999960000000002, 'AbsTol', 1e-12);
            testCase.verifyEqual(analysis.Qc_C, 0.01, 'AbsTol', 1e-15);
            testCase.verifyEqual(analysis.Qa_C, 0.01, 'AbsTol', 1e-15);
            testCase.verifyEqual(analysis.Qt_C, 0.02, 'AbsTol', 1e-15);
            testCase.verifyEqual(analysis.CICc_mCcm2, 10, 'AbsTol', 1e-12);
            testCase.verifyEqual(analysis.CICt_mCcm2, 20, 'AbsTol', 1e-12);
            testCase.verifyEqual(analysis.message, 'OK');
            testCase.verifyFalse(analysis.cathOK);
            testCase.verifyFalse(analysis.anodOK);
            testCase.verifyFalse(analysis.safe);
            testCase.verifyEqual(analysis.limitSide, 'both exceeded');
        end

        function preservesBaselineAndVoltageAccessPolicies(testCase)
            item = testfixtures.makeChronoFixtureItem();
            analysis = cic.analysisRun.computeCIC(item, defaultOptions());

            testCase.verifyTrue(analysis.ok, analysis.message);
            testCase.verifyEqual(analysis.Epre, 0, 'AbsTol', 1e-12);
            testCase.verifyEqual(analysis.Ebetween, 0, 'AbsTol', 1e-12);
            testCase.verifyEqual(analysis.Epost, 0, 'AbsTol', 1e-12);
            testCase.verifyEqual(analysis.Eipp, 0, 'AbsTol', 1e-12);
            testCase.verifyEqual(analysis.Eipp_gap, 0, 'AbsTol', 1e-12);
            testCase.verifyEqual(analysis.baselineCathSource, 'pre-pulse median');
            testCase.verifyEqual(analysis.baselineAnodSource, 'interpulse median');
            testCase.verifyEqual(analysis.Vc_on, -1, 'AbsTol', 1e-12);
            testCase.verifyEqual(analysis.Va_on, 1, 'AbsTol', 1e-12);
            testCase.verifyEqual(analysis.Va_cath_mag, 1, 'AbsTol', 1e-12);
            testCase.verifyEqual(analysis.Va_anod_mag, 1, 'AbsTol', 1e-12);
        end

        function supportsNominalCurrentAndSharedBatchRecomputation(testCase)
            item = testfixtures.makeChronoFixtureItem();
            options = defaultOptions();
            options.usedMeasuredCurrent = false;
            nominal = cic.analysisRun.computeCIC(item, options);

            testCase.verifyTrue(nominal.ok, nominal.message);
            testCase.verifyEqual(nominal.Qc_C, 0.01, 'AbsTol', 1e-15);
            testCase.verifyEqual(nominal.Qa_C, 0.01, 'AbsTol', 1e-15);
            testCase.verifyEqual(nominal.Qt_C, 0.02, 'AbsTol', 1e-15);

            options.areaOverride = '2';
            batch = [item, item];
            [batch.analysis] = deal(struct('ok', false));
            batch = cic.analysisRun.recomputeItems(batch, options);
            analyses = [batch.analysis];
            testCase.verifyTrue(all([analyses.ok]));
            testCase.verifyEqual([analyses.area_cm2], [2, 2], 'AbsTol', 1e-15);
        end

        function appliesAreaAndWaterWindowPolicy(testCase)
            item = testfixtures.makeChronoFixtureItem();
            options = defaultOptions();
            options.areaOverride = '2';
            options.cathLimit = -2;
            options.anodLimit = 2;
            analysis = cic.analysisRun.computeCIC(item, options);

            testCase.verifyTrue(analysis.ok, analysis.message);
            testCase.verifyEqual(analysis.area_cm2, 2, 'AbsTol', 1e-15);
            testCase.verifyEqual(analysis.CICc_mCcm2, 5, 'AbsTol', 1e-12);
            testCase.verifyEqual(analysis.CICt_mCcm2, 10, 'AbsTol', 1e-12);
            testCase.verifyTrue(analysis.safe);
        end

        function reportsInvalidDataWithoutExtrapolation(testCase)
            item = testfixtures.makeChronoFixtureItem();
            options = defaultOptions();
            options.delay_s = 1e6;
            outside = cic.analysisRun.computeCIC(item, options);
            missing = cic.analysisRun.computeCIC( ...
                struct('meta', struct(), 'tables', struct([])), struct());

            testCase.verifyFalse(outside.ok);
            testCase.verifySubstring(outside.message, 'outside the recorded time range');
            testCase.verifyFalse(missing.ok);
            testCase.verifyEqual(missing.message, 'Main transient table not found.');
        end
    end
end

function options = defaultOptions()
    choices = cic.analysisRun.analysisChoices();
    options = struct( ...
        'delay_s', 10e-6, ...
        'cathLimit', -0.6, ...
        'anodLimit', 0.8, ...
        'areaOverride', '', ...
        'pulseMode', char(choices.pulseModes(1)), ...
        'usedMeasuredCurrent', true);
end
