classdef EisSourceSpec < matlab.unittest.TestCase
    %EISSOURCESPEC Specify EIS canonical source fields and path filtering.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function identifiesOnlyExactFinalNumericSuffixes(testCase)
            % Oracle: only final -digits are removed; case and earlier hyphens remain.
            names = ["sample-x-1.DTA", "sample-x-2.DTA", "sample-X-3.DTA", ...
                "sample-x-1-extra.DTA", "sample-x.DTA", "sample-x-4.DTA"];
            sources = repmat(labkit.app.source.record("s1", "eis", names(1)), 1, numel(names));
            for k = 1:numel(names)
                sources(k) = labkit.app.source.record("s"+k, "eis", names(k));
            end
            item = struct("freq_Hz", [100;10], "Zreal_ohm", [1;2], "negZimag_ohm", [2;3]);
            items = repmat(item, 1, numel(names));
            existing = struct("name", "Manual", "sourceIds", "s6");
            [groups, rejected] = eis.sourceFiles.identifyGroups(items, sources, existing);
            testCase.verifyEmpty(rejected);
            testCase.verifyEqual(string({groups.name}), ["Manual", "sample-x", "sample-X"]);
            testCase.verifyEqual(groups(2).sourceIds, ["s1", "s2"]);
            testCase.verifyEqual(groups(1).sourceIds, "s6");
            items(2).freq_Hz(1) = 101;
            [groups, rejected] = eis.sourceFiles.identifyGroups(items, sources, existing);
            testCase.verifyEqual(string({groups.name}), ["Manual", "sample-X"]);
            testCase.assertNumElements(rejected, 1);
            testCase.verifyEqual(rejected{1}.identifier, 'eis:GroupFrequencyMismatch');
        end

        function loadsCanonicalZcurveItems(testCase)
            [item, status] = labkit.dta.loadFile( ...
                testfixtures.dta.file("eis_potentiostatic_zcurve.DTA"), "eis");
            testCase.assertTrue(status.ok, status.message);

            testCase.verifyEqual(string(item.type), "eis");
            testCase.verifyEqual(item.message, 'Using table: ZCURVE');
            testCase.verifyEqual(item.zcurve, item.curve);
            testCase.verifyEqual(numel(item.freq_Hz), item.n);
        end

        function acceptsOnlyEisDtaPaths(testCase)
            eisPath = testfixtures.dta.file( ...
                "eis_potentiostatic_zcurve.DTA");
            chrono = testfixtures.dta.file( ...
                "chrono_chronopot_current_pulse_0p2ms.DTA");

            accepted = eis.sourceFiles.matchesDtaKind([eisPath, chrono]);

            testCase.verifyEqual(accepted, [true false]);
        end
    end
end
