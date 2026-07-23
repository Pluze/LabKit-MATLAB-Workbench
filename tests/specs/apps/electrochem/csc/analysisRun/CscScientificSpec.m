classdef CscScientificSpec < matlab.unittest.TestCase
    %CSCSCIENTIFICSPEC Specify CV/CT charge and CSC calculations.

    methods (Test, TestTags = {'Contract:scientific', 'Env:headless'})
        function calculatesFullCycleChargeAndAreaNormalizedCsc(testCase)
            [item, curve] = CscScientificSpec.referenceCurve(testCase);
            choices = csc.analysisRun.analysisChoices();
            options = struct("scanRate", item.scanRate, ...
                "mode", choices.modes(1), "area_cm2", "2");

            analysis = csc.analysisRun.computeCSC(curve, options);

            testCase.verifyTrue(analysis.ok, analysis.message);
            testCase.verifyEqual(string(analysis.mode), choices.modes(1));
            testCase.verifyEqual([analysis.Qct, analysis.Qcv, analysis.diff_C], ...
                [0.0015, 0.0075, -0.006], "AbsTol", 1e-16);
            testCase.verifyEqual(analysis.rel_pct, 80, "AbsTol", 1e-12);
            testCase.verifyEqual([analysis.Qct_mC_cm2, analysis.Qcv_mC_cm2], ...
                [0.75, 3.75], "AbsTol", 1e-13);
        end

        function selectsCathodicModeAndReportsInvalidInputs(testCase)
            [item, curve] = CscScientificSpec.referenceCurve(testCase);
            choices = csc.analysisRun.analysisChoices();
            cathodic = csc.analysisRun.computeCSC(curve, struct( ...
                "scanRate", item.scanRate, "mode", choices.modes(2), "area_cm2", "2"));
            missingRate = csc.analysisRun.computeCSC(curve, struct("scanRate", NaN));
            missingColumns = curve;
            missingColumns = rmfield(missingColumns, "headers");
            malformed = csc.analysisRun.computeCSC(missingColumns, ...
                struct("scanRate", item.scanRate));

            testCase.verifyTrue(cathodic.ok, cathodic.message);
            testCase.verifyEqual([cathodic.Qct, cathodic.Qcv], ...
                [0.00025, 0.00125], "AbsTol", 1e-16);
            testCase.verifyEqual(cathodic.Qct_mC_cm2, 0.125, "AbsTol", 1e-13);
            testCase.verifyFalse(missingRate.ok);
            testCase.verifyEqual(string(missingRate.message), "scan rate missing");
            testCase.verifyFalse(malformed.ok);
            testCase.verifyEqual(string(malformed.message), "Need T, Vf, Im");
        end
    end

    methods (Static, Access = private)
        function [item, curve] = referenceCurve(testCase)
            [item, status] = labkit.dta.loadFile( ...
                testfixtures.dtaFixturePath("cv_cyclic_voltammetry_pt_reference.DTA"), "cvct");
            testCase.assertTrue(status.ok, status.message);
            curve = item.curves(1);
        end
    end
end
