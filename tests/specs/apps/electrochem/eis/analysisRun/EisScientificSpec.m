classdef EisScientificSpec < matlab.unittest.TestCase
    %EISSCIENTIFICSPEC Specify canonical EIS axis-value calculations.

    methods (Test, TestTags = {'Contract:scientific', 'Env:headless'})
        function mapsCanonicalImpedanceAndLogFrequencyAxes(testCase)
            item = EisScientificSpec.canonicalItem(testCase);
            axes = eis.overlayPlot.axisItems();

            realImpedance = eis.analysisRun.valuesForAxis(item, axes(5));
            logFrequency = eis.analysisRun.valuesForAxis(item, axes(2));

            testCase.verifyEqual(realImpedance, item.Zreal_ohm, "AbsTol", 1e-12);
            testCase.verifyEqual(logFrequency, log10(item.freq_Hz), "AbsTol", 1e-12);
            testCase.verifyEqual(realImpedance(1), 138.7798, "AbsTol", 1e-12);
        end
    end

    methods (Static, Access = private)
        function item = canonicalItem(testCase)
            [item, status] = labkit.dta.loadFile( ...
                testfixtures.dtaFixturePath("eis_potentiostatic_zcurve.DTA"), "eis");
            testCase.assertTrue(status.ok, status.message);
            legacy = {"Pt", "Time", "Freq", "Zreal", "Zimag", "negZimag", ...
                "Zmod", "Zphz", "Idc", "Vdc"};
            present = legacy(isfield(item, legacy));
            if ~isempty(present)
                item = rmfield(item, present);
            end
        end
    end
end
