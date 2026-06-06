classdef CscViewTest < matlab.unittest.TestCase
    %CSCVIEWTEST Verify GUI-free CSC display helpers.

    methods (Test, TestTags = {'Unit'})
        function chargeFormattingPreservesLegacyText(testCase)
            setupLabKitTestPath();

            testCase.verifyEqual( ...
                csc.view.formatChargeAndCSC(1.25e-4, NaN), ...
                sprintf('%.12e C', 1.25e-4));
            testCase.verifyEqual( ...
                csc.view.formatChargeAndCSC(1.25e-4), ...
                sprintf('%.12e C', 1.25e-4));
            testCase.verifyEqual( ...
                csc.view.formatChargeAndCSC(1.25e-4, 0), ...
                sprintf('%.12e C', 1.25e-4));
            testCase.verifyEqual( ...
                csc.view.formatChargeAndCSC(1.25e-4, 2), ...
                sprintf('%.12e C | %.12e mC/cm^2', 1.25e-4, 1e3 * 1.25e-4 / 2));
        end

        function defaultPlotSelectionsPreferLegacyCvctColumns(testCase)
            setupLabKitTestPath();

            selections = csc.view.defaultPlotSelections({'T', 'Vf', 'Im', 'Vu'});

            testCase.verifyEqual(selections.topX, 'Vf');
            testCase.verifyEqual(selections.topY, 'Im');
            testCase.verifyEqual(selections.bottomX, 'T');
            testCase.verifyEqual(selections.bottomY, 'Im');
        end

        function defaultPlotSelectionsFallBackToFirstColumn(testCase)
            setupLabKitTestPath();

            selections = csc.view.defaultPlotSelections({'Potential', 'Current'});

            testCase.verifyEqual(selections.topX, 'Potential');
            testCase.verifyEqual(selections.topY, 'Potential');
            testCase.verifyEqual(selections.bottomX, 'Potential');
            testCase.verifyEqual(selections.bottomY, 'Potential');
        end

        function trimOverlayDataPreparesLegacyTrimVectors(testCase)
            setupLabKitTestPath();

            result = struct( ...
                'IcathDisp', [NaN -2 -3], ...
                'IanodDisp', [1 NaN 3]);

            overlay = csc.view.trimOverlayData(true, 'Im', [0 1 2], result);

            testCase.verifyTrue(overlay.ok);
            testCase.verifyEqual(overlay.x, [0 1 2]);
            testCase.verifyEqual(overlay.cathY, result.IcathDisp);
            testCase.verifyEqual(overlay.anodY, result.IanodDisp);
        end

        function trimOverlayDataRejectsNonCurrentAndMismatchedVectors(testCase)
            setupLabKitTestPath();

            result = struct( ...
                'IcathDisp', [NaN -2 -3], ...
                'IanodDisp', [1 NaN 3]);

            disabled = csc.view.trimOverlayData(false, 'Im', [0 1 2], result);
            voltageAxis = csc.view.trimOverlayData(true, 'Vf', [0 1 2], result);
            mismatchedX = csc.view.trimOverlayData(true, 'Im', [0 1], result);

            testCase.verifyFalse(disabled.ok);
            testCase.verifyFalse(voltageAxis.ok);
            testCase.verifyFalse(mismatchedX.ok);
        end

        function comparisonReadoutFormatsSuccessfulComparison(testCase)
            setupLabKitTestPath();

            result = struct( ...
                'ok', true, ...
                'Qct', 1.25e-4, ...
                'Qcv', 1.5e-4, ...
                'diff_C', -2.5e-5, ...
                'rel_pct', 18.1818181818, ...
                'dtErr', 3.25e-6, ...
                'area_cm2', 2);

            readout = csc.view.comparisonReadout(result, 'Cathodic');

            testCase.verifyTrue(readout.ok);
            testCase.verifyEqual(readout.qctText, ...
                sprintf('%.12e C | %.12e mC/cm^2', result.Qct, 1e3 * result.Qct / 2));
            testCase.verifyEqual(readout.qcvText, ...
                sprintf('%.12e C | %.12e mC/cm^2', result.Qcv, 1e3 * result.Qcv / 2));
            testCase.verifyEqual(readout.diffText, ...
                sprintf('%.12e C | %.12e mC/cm^2', result.diff_C, 1e3 * result.diff_C / 2));
            testCase.verifyEqual(readout.relText, sprintf('%.6f %%', result.rel_pct));
            testCase.verifyEqual(readout.dtErrText, sprintf('%.6e s', result.dtErr));
            testCase.verifyEqual(readout.statusText, 'CSC normalized by 2 cm^2');
            testCase.verifyEqual(readout.logMessage, ...
                sprintf(['Compare [%s]: Qct=%.6e C, Qcv=%.6e C, ', ...
                'rel=%.6f %%, maxdt=%.3e s'], ...
                'Cathodic', result.Qct, result.Qcv, result.rel_pct, result.dtErr));
        end

        function comparisonReadoutPreservesChargeOnlyStatus(testCase)
            setupLabKitTestPath();

            result = struct( ...
                'ok', true, ...
                'Qct', 1.25e-4, ...
                'Qcv', 1.5e-4, ...
                'diff_C', -2.5e-5, ...
                'rel_pct', 18.1818181818, ...
                'dtErr', 3.25e-6, ...
                'area_cm2', NaN);

            readout = csc.view.comparisonReadout(result, 'Full');

            testCase.verifyEqual(readout.qctText, sprintf('%.12e C', result.Qct));
            testCase.verifyEqual(readout.diffText, sprintf('%.12e C', result.diff_C));
            testCase.verifyEqual(readout.statusText, 'Charge shown (area not set)');
        end

        function comparisonReadoutPreservesFailureDisplay(testCase)
            setupLabKitTestPath();

            result = struct( ...
                'ok', false, ...
                'message', 'No matching CV/CT curve data.', ...
                'logMessage', 'Compare skipped: No matching CV/CT curve data.');

            readout = csc.view.comparisonReadout(result, 'Full');

            testCase.verifyFalse(readout.ok);
            testCase.verifyEqual(readout.qctText, result.message);
            testCase.verifyEqual(readout.qcvText, result.message);
            testCase.verifyEqual(readout.diffText, '-');
            testCase.verifyEqual(readout.relText, '-');
            testCase.verifyEqual(readout.dtErrText, '-');
            testCase.verifyEqual(readout.statusText, '');
            testCase.verifyEqual(readout.logMessage, result.logMessage);
        end
    end
end
