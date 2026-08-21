classdef EisScientificSpec < matlab.unittest.TestCase
    %EISSCIENTIFICSPEC Specify canonical EIS axis-value calculations.

    methods (Test, TestTags = {'Contract:scientific', 'Env:headless'})
        function mapsCanonicalImpedanceAndLogFrequencyAxes(testCase)
            item = EisScientificSpec.canonicalItem(testCase);
            axes = eis.overlayPlot.axisItems();
            units = eis.impedanceDisplay.catalog();

            realImpedance = eis.analysisRun.valuesForAxis( ...
                item, axes(5), units.choices(3));
            logFrequency = eis.analysisRun.valuesForAxis(item, axes(2));
            milliohm = eis.analysisRun.valuesForAxis( ...
                item, axes(5), units.choices(1));
            ohm = eis.analysisRun.valuesForAxis( ...
                item, axes(5), units.choices(2));
            megohm = eis.analysisRun.valuesForAxis( ...
                item, axes(5), units.choices(4));

            testCase.verifyEqual(realImpedance, ...
                item.Zreal_ohm / 1e3, "AbsTol", 1e-12);
            testCase.verifyEqual(logFrequency, log10(item.freq_Hz), "AbsTol", 1e-12);
            testCase.verifyEqual(milliohm, item.Zreal_ohm * 1e3, ...
                "RelTol", 1e-12);
            testCase.verifyEqual(ohm, item.Zreal_ohm, "AbsTol", 1e-12);
            testCase.verifyEqual(megohm, item.Zreal_ohm / 1e6, ...
                "AbsTol", 1e-12);
        end
    end

    methods (Static, Access = private)
        function item = canonicalItem(testCase)
            [item, status] = labkit.dta.loadFile( ...
                testfixtures.dta.file("eis_potentiostatic_zcurve.DTA"), "eis");
            testCase.assertTrue(status.ok, status.message);
        end
    end
end
