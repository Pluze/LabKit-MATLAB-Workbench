classdef CicViewTest < matlab.unittest.TestCase
    %CICVIEWTEST Verify GUI-free CIC display helpers.

    methods (Test, TestTags = {'Unit'})
        function displayUnitNormalizesKnownAndFallbackLabels(testCase)
            setupLabKitTestPath();

            [scale, label, suffix] = cic.view.displayUnit('uC/cm^2');
            testCase.verifyEqual(scale, 1e3);
            testCase.verifyEqual(label, 'uC/cm^2');
            testCase.verifyEqual(suffix, 'uCcm2');

            [scale, label, suffix] = cic.view.displayUnit('unexpected');
            testCase.verifyEqual(scale, 1);
            testCase.verifyEqual(label, 'mC/cm^2');
            testCase.verifyEqual(suffix, 'mCcm2');
        end

        function currentSummaryBuildsSuccessfulRowsAndBestSafeValue(testCase)
            setupLabKitTestPath();

            items = makeItems();
            summary = cic.view.buildCurrentSummary(items, 1, ...
                'Cathodic phase', 'uC/cm^2');

            testCase.verifyEqual(summary.controlMode, 'Current-controlled chrono');
            testCase.verifyEqual(summary.detect, 'metadata-current | pulse metadata');
            testCase.verifyEqual(summary.delay, '10.000 us');
            testCase.verifyEqual(summary.area, '1.25 cm^2');
            testCase.verifyEqual(summary.emc, '-0.612867 V @ 12.300000us');
            testCase.verifyEqual(summary.ema, '0.596233 V @ 22.400000us');
            testCase.verifyEqual(summary.qc, sprintf('%.6e C | %.6f uC/cm^2', 2.5e-6, 2.5));
            testCase.verifyEqual(summary.qa, sprintf('%.6e C | %.6f uC/cm^2', 3.5e-6, 3.5));
            testCase.verifyEqual(summary.qt, sprintf('%.6e C | %.6f uC/cm^2', 6.0e-6, 6.0));
            testCase.verifyEqual(summary.safe, 'UNSAFE | Emc>=-0.600? 0 | Ema<=0.800? 1');
            testCase.verifyEqual(summary.bestSafe, 'safe-second | CICc = 9 uC/cm^2');
        end

        function currentSummaryHandlesFailedAnalysis(testCase)
            setupLabKitTestPath();

            items = makeItems();
            items(1).controlMode = 'unknown';
            items(1).analysis = struct('ok', false, 'message', 'bad pulse window');
            items(2).analysis.safe = false;

            summary = cic.view.buildCurrentSummary(items, 1, ...
                'Total biphasic', 'mC/cm^2');

            testCase.verifyEqual(summary.controlMode, 'Unknown chrono control mode');
            testCase.verifyEqual(summary.detect, '-');
            testCase.verifyEqual(summary.delay, '-');
            testCase.verifyEqual(summary.qc, '-');
            testCase.verifyEqual(summary.safe, 'bad pulse window');
            testCase.verifyEqual(summary.bestSafe, 'No safe file in current batch');
        end

        function currentSummaryPreservesBestSafeWithoutCurrentItem(testCase)
            setupLabKitTestPath();

            items = makeItems();

            summary = cic.view.buildCurrentSummary(items, [], ...
                'Total biphasic', 'mC/cm^2');
            testCase.verifyEqual(summary.controlMode, '-');
            testCase.verifyEqual(summary.bestSafe, 'safe-second | CICtotal = 0.012 mC/cm^2');

            emptySummary = cic.view.buildCurrentSummary(struct([]), [], ...
                'Total biphasic', 'mC/cm^2');
            testCase.verifyEqual(emptySummary.bestSafe, '-');
        end
    end
end

function items = makeItems()
    base = struct( ...
        'name', '', ...
        'controlMode', 'current', ...
        'analysis', []);

    items = repmat(base, 1, 2);
    items(1).name = 'current-file';
    items(1).analysis = makeAnalysis(false, 0.0025, 0.0035, 0.0060);

    items(2).name = 'safe-second';
    items(2).controlMode = 'voltage';
    items(2).analysis = makeAnalysis(true, 0.0090, 0.0040, 0.0120);
end

function A = makeAnalysis(isSafe, cCath, cAnod, cTotal)
    A = struct( ...
        'ok', true, ...
        'detectMode', 'metadata-current', ...
        'detectMsg', 'pulse metadata', ...
        'delay_s', 10e-6, ...
        'area_cm2', 1.25, ...
        'Emc', -0.6128669999, ...
        't_emc', 12.3e-6, ...
        'Ema', 0.596233, ...
        't_ema', 22.4e-6, ...
        'Qc_C', 2.5e-6, ...
        'Qa_C', 3.5e-6, ...
        'Qt_C', 6.0e-6, ...
        'CICc_mCcm2', cCath, ...
        'CICa_mCcm2', cAnod, ...
        'CICt_mCcm2', cTotal, ...
        'safe', isSafe, ...
        'cathLimit', -0.6, ...
        'cathOK', false, ...
        'anodLimit', 0.8, ...
        'anodOK', true);
end
