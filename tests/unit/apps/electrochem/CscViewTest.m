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
    end
end
