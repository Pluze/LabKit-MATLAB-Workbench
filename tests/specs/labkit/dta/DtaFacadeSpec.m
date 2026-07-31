classdef DtaFacadeSpec < matlab.unittest.TestCase
    %DTAFACADEPEC Specify public DTA discovery, loading, and failure behavior.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function findsAndClassifiesSupportedDtaFiles(testCase)
            fixtureFolder = testfixtures.dtaFixtureDir();
            chrono = testfixtures.dtaFixturePath('chrono_chronopot_current_pulse_0p2ms.DTA');
            eis = testfixtures.dtaFixturePath('eis_potentiostatic_zcurve.DTA');
            cvct = testfixtures.dtaFixturePath('cv_cyclic_voltammetry_pt_reference.DTA');

            files = labkit.dta.findFiles(fixtureFolder);

            testCase.verifyGreaterThanOrEqual(numel(files), 8);
            testCase.verifyTrue(all(endsWith(lower(string(files)), '.dta')));
            testCase.verifyTrue(any(strcmp(files, chrono)));
            testCase.verifyEqual(labkit.dta.detectType(chrono), "chrono");
            testCase.verifyEqual(labkit.dta.detectType(eis), "eis");
            testCase.verifyEqual(labkit.dta.detectType(cvct), "cvct");
        end

        function loadsCanonicalItemsAndReportsRecoverableFailures(testCase)
            chrono = testfixtures.dtaFixturePath('chrono_chronopot_current_pulse_0p2ms.DTA');
            eis = testfixtures.dtaFixturePath('eis_potentiostatic_zcurve.DTA');
            cvct = testfixtures.dtaFixturePath('cv_cyclic_voltammetry_pt_reference.DTA');

            [chronoItem, chronoStatus] = labkit.dta.loadFile(chrono, " Chrono ");
            [eisItem, eisStatus] = labkit.dta.loadFile(eis);
            [cvctItem, cvctStatus] = labkit.dta.loadFile(cvct, "cvct");
            [mismatch, mismatchStatus] = labkit.dta.loadFile(eis, "chrono");
            [items, report] = labkit.dta.loadFiles({chrono, eis, cvct}, "auto");

            testCase.verifyTrue(chronoStatus.ok, chronoStatus.message);
            testCase.verifyEqual(chronoStatus.code, "ok");
            testCase.verifyEqual(chronoItem.type, "chrono");
            testCase.verifyTrue(all(isfield(chronoItem, {'t_s', 'Vf_V', 'Im_A'})));
            testCase.verifyFalse(any(isfield(chronoItem, {'t', 'Vf', 'Im'})));
            testCase.verifyTrue(eisStatus.ok, eisStatus.message);
            testCase.verifyEqual(eisItem.type, "eis");
            testCase.verifyTrue(all(isfield(eisItem, {'freq_Hz', 'Zreal_ohm', 'Zimag_ohm'})));
            testCase.verifyFalse(any(isfield(eisItem, ...
                {'Freq', 'Zreal', 'Zimag', 'Pt', 'Time'})));
            testCase.verifyTrue(cvctStatus.ok, cvctStatus.message);
            testCase.verifyEqual(cvctItem.type, "cvct");
            testCase.verifyNotEmpty(cvctItem.curves);
            testCase.verifyEmpty(mismatch);
            testCase.verifyFalse(mismatchStatus.ok);
            testCase.verifyEqual(mismatchStatus.code, "kind_mismatch");
            testCase.verifyEqual(mismatchStatus.kind, "eis");
            testCase.verifySubstring(mismatchStatus.message, "Expected chrono DTA");
            testCase.verifyEqual(numel(items), 3);
            testCase.verifyEqual([report.nRequested, report.nLoaded, report.nFailed], [3, 3, 0]);
        end

        function reportsStableMachineReadableFailureCodes(testCase)
            missing = fullfile(tempdir, "labkit-missing-dta-file.DTA");
            [kind, detectStatus] = labkit.dta.detectType(missing);
            [item, loadStatus] = labkit.dta.loadFile(missing, "chrono");

            testCase.verifyEqual(kind, "unknown");
            testCase.verifyEqual(detectStatus.code, "missing_file");
            testCase.verifyEmpty(item);
            testCase.verifyEqual(loadStatus.code, "missing_file");
            testCase.verifySubstring(loadStatus.message, "File not found");
        end
    end
end
