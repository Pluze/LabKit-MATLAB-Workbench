classdef CicViewTest < matlab.unittest.TestCase
    %CICVIEWTEST Verify GUI-free CIC display helpers.

    methods (Test, TestTags = {'Unit'})
        function displayUnitNormalizesKnownAndFallbackLabels(testCase)
            setupLabKitTestPath();

            [scale, label, suffix] = cic.userInterface.displayUnit('uC/cm^2');
            testCase.verifyEqual(scale, 1e3);
            testCase.verifyEqual(label, 'uC/cm^2');
            testCase.verifyEqual(suffix, 'uCcm2');

            [scale, label, suffix] = cic.userInterface.displayUnit('unexpected');
            testCase.verifyEqual(scale, 1);
            testCase.verifyEqual(label, 'mC/cm^2');
            testCase.verifyEqual(suffix, 'mCcm2');
        end

        function currentSummaryBuildsSuccessfulRowsAndBestSafeValue(testCase)
            setupLabKitTestPath();

            items = makeItems();
            choices = cic.userInterface.analysisChoices();
            summary = cic.userInterface.buildCurrentSummary(items, 1, ...
                choices.cicModes(1), 'uC/cm^2');

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
            choices = cic.userInterface.analysisChoices();

            summary = cic.userInterface.buildCurrentSummary(items, 1, ...
                choices.cicModes(3), 'mC/cm^2');

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
            choices = cic.userInterface.analysisChoices();

            summary = cic.userInterface.buildCurrentSummary(items, [], ...
                choices.cicModes(3), 'mC/cm^2');
            testCase.verifyEqual(summary.controlMode, '-');
            testCase.verifyEqual(summary.bestSafe, 'safe-second | CICtotal = 0.012 mC/cm^2');

            emptySummary = cic.userInterface.buildCurrentSummary(struct([]), [], ...
                choices.cicModes(3), 'mC/cm^2');
            testCase.verifyEqual(emptySummary.bestSafe, '-');
        end

        function plotRequestBuildsTimeVoltagePayload(testCase)
            setupLabKitTestPath();

            A = makeAnalysis(false, 0.0025, 0.0035, 0.0060);
            choices = cic.userInterface.analysisChoices();

            request = cic.userInterface.plotRequest(A, 'sample-file', ...
                choices.xAxes(1), choices.yAxes(1));

            testCase.verifyEqual(request.kind, 'VT');
            testCase.verifyEqual(request.x, A.t);
            testCase.verifyEqual(request.y, A.Vf);
            testCase.verifyEqual(string(request.xLabel), choices.xAxes(1));
            testCase.verifyEqual(request.yLabel, 'Vf (V vs Ref.)');
            testCase.verifyEqual(request.baseColor, [0 0.4470 0.7410]);
            testCase.verifyEqual(request.title, 'sample-file | VT | UNSAFE');
            testCase.verifyEqual(request.coords.cathStartX, A.pulse.cath_start);
            testCase.verifyEqual(request.coords.cathEndX, A.pulse.cath_end);
            testCase.verifyEqual(request.coords.anodStartX, A.pulse.anod_start);
            testCase.verifyEqual(request.coords.anodEndX, A.pulse.anod_end);
            testCase.verifyEqual(request.coords.emcX, A.t_emc);
            testCase.verifyEqual(request.coords.emaX, A.t_ema);
        end

        function plotRequestBuildsSampleCurrentPayload(testCase)
            setupLabKitTestPath();

            A = makeAnalysis(true, 0.0090, 0.0040, 0.0120);
            choices = cic.userInterface.analysisChoices();

            request = cic.userInterface.plotRequest(A, 'safe-file', ...
                choices.xAxes(2), choices.yAxes(2));

            testCase.verifyEqual(request.kind, 'IT');
            testCase.verifyEqual(request.x, A.pt);
            testCase.verifyEqual(request.y, A.Im);
            testCase.verifyEqual(string(request.xLabel), choices.xAxes(2));
            testCase.verifyEqual(request.yLabel, 'Im (A)');
            testCase.verifyEqual(request.baseColor, [0.8500 0.3250 0.0980]);
            testCase.verifyEqual(request.title, 'safe-file | IT | |I|max = 0.0035 A');
            testCase.verifyEqual(request.coords.cathStartX, 2);
            testCase.verifyEqual(request.coords.cathEndX, 4);
            testCase.verifyEqual(request.coords.anodStartX, 6);
            testCase.verifyEqual(request.coords.anodEndX, 8);
            testCase.verifyEqual(request.coords.emcX, 2.46, 'AbsTol', 1e-12);
            testCase.verifyEqual(request.coords.emaX, 4.48, 'AbsTol', 1e-12);
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
        'anodOK', true, ...
        'ampEstimate_A', 0.0035, ...
        't', [0 1 2 3 4] * 10e-6, ...
        'pt', [0 2 4 6 8], ...
        'Vf', [-0.1 -0.4 -0.8 0.2 0.6], ...
        'Im', [0 0.001 -0.002 0.003 0], ...
        'pulse', struct( ...
            'cath_start', 10e-6, ...
            'cath_end', 20e-6, ...
            'anod_start', 30e-6, ...
            'anod_end', 40e-6));
end
