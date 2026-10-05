classdef EisScientificSpec < matlab.unittest.TestCase
    %EISSCIENTIFICSPEC Specify canonical EIS axis-value calculations.

    methods (Test, TestTags = {'Contract:scientific', 'Env:headless'})
        function groupsByFrequencyWithPairedCountsAndSampleSD(testCase)
            % Oracle: two scans [1,3] have mean 2 and sample SD sqrt(2).
            % Pairing by row, population SD, or independent NaN masks fails.
            a = struct("freq_Hz", [100;10;1], "Zreal_ohm", [1000;2000;3000], ...
                "negZimag_ohm", [4000;5000;6000], "Zphz_deg", [179;10;30]);
            b = struct("freq_Hz", [1;100;10], "Zreal_ohm", [7000;3000;NaN], ...
                "negZimag_ohm", [10000;8000;9000], "Zphz_deg", [50;-179;20]);
            actual = eis.analysisRun.groupCoordinates([a b], "Zreal", "-Zimag", "kΩ");
            testCase.verifyEqual(actual.x, [2;2;5]);
            testCase.verifyEqual(actual.y, [6;5;8]);
            testCase.verifyEqual(actual.n, [2;1;2]);
            testCase.verifyEqual(actual.xSD, [sqrt(2);NaN;sqrt(8)], AbsTol=1e-12);
            testCase.verifyEqual(actual.ySD, [sqrt(8);NaN;sqrt(8)], AbsTol=1e-12);
            testCase.verifyEqual(actual, eis.analysisRun.groupCoordinates( ...
                [a b], "Zreal", "-Zimag", "kΩ"));
            phase = eis.analysisRun.groupCoordinates([a b], "Freq (Hz)", "Zphz (deg)", "Ω");
            testCase.verifyEqual(abs(phase.y(1)), 180, AbsTol=1e-12);
            testCase.verifyEqual(phase.ySD(1), sqrt(2), AbsTol=1e-12);
            testCase.verifyEqual(phase.xSD, zeros(3,1));
            a.Zreal_ohm(3) = NaN;
            b.Zreal_ohm(1) = NaN;
            missing = eis.analysisRun.groupCoordinates([a b], "Zreal", "-Zimag", "Ω");
            testCase.verifyEqual(missing.n(3), 0);
            testCase.verifyTrue(isnan(missing.x(3)) && isnan(missing.ySD(3)));
        end

        function rejectsAmbiguousFrequencyPairing(testCase)
            a = struct("freq_Hz", [100;10], "Zreal_ohm", [1;2]);
            b = a;
            b.freq_Hz(1) = 101;
            testCase.verifyError(@() eis.analysisRun.groupCoordinates( ...
                [a b], "Zreal", "Zreal", "Ω"), "eis:GroupFrequencyMismatch");
            for invalid = {[10;10], [100;0], [100;NaN]}
                b.freq_Hz = invalid{1};
                testCase.verifyError(@() eis.analysisRun.groupCoordinates( ...
                    [a b], "Zreal", "Zreal", "Ω"), "eis:InvalidGroupFrequency");
            end
        end

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
