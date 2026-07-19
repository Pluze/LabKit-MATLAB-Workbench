classdef ElectrochemDebugSamplePackTest < matlab.unittest.TestCase
    %ELECTROCHEMDEBUGSAMPLEPACKTEST Verify electrochem debug sample packs.

    methods (Test, TestTags = {'Unit'})
        function electrochem_debug_sample_packs_load_through_dta_facade(testCase)
            setupLabKitTestPath();
            fixtureRoot = string(tempname);
            cleanup = onCleanup(@() cleanupFolder(fixtureRoot));
            mkdir(char(fixtureRoot));

            debug = debugSampleContext(fixtureRoot);

            verifyChronoOverlayPack(testCase, chrono_overlay.debug.writeSamplePack(debug));
            verifyChronoPack(testCase, cic.debug.writeSamplePack(debug), "labkit_CIC_app");
            verifyChronoPack(testCase, vt_resistance.debug.writeSamplePack(debug), "labkit_VTResistance_app");
            verifyCvctPack(testCase, csc.debug.writeSamplePack(debug));
            verifyEisPack(testCase, eis.debug.writeSamplePack(debug));

            testCase.verifyTrue(isfile(debug.manifestFile), ...
                "Debug sample writers should record a session manifest.");
            manifestText = string(fileread(debug.manifestFile));
            testCase.verifyTrue(contains(manifestText, "labkit_EIS_app"), ...
                "The last recorded manifest should identify the app-owned sample pack.");
            testCase.verifyTrue(contains(manifestText, "outputFolder"), ...
                "Manifest payload should retain the debug output folder.");
        end
    end
end

function verifyChronoOverlayPack(testCase, pack)
    testCase.verifyEqual(numel(pack.representativeFiles), 2, ...
        "Chrono overlay debug pack should provide two representative chrono files.");
    for k = 1:numel(pack.representativeFiles)
        item = loadDta(testCase, pack.representativeFiles(k), "chrono");
        testCase.verifyGreaterThan(numel(item.t), 20, ...
            "Chrono overlay samples should contain tabular time-series rows.");
        testCase.verifyTrue(any(isfinite(item.Vf)) && any(isfinite(item.Im)), ...
            "Chrono overlay samples should include finite voltage and current data.");
    end
    verifyBoundaryFiles(testCase, pack.boundaryFiles, "chrono");
end

function verifyChronoPack(testCase, pack, appName)
    testCase.verifyEqual(string(pack.manifest.app), appName);
    item = loadDta(testCase, pack.representativeFiles, "chrono");
    testCase.verifyGreaterThan(numel(item.t), 20, ...
        "Chrono debug samples should contain representative rows.");
    testCase.verifyTrue(any(abs(item.Im) > 0), ...
        "Chrono debug samples should include current response data.");
    verifyBoundaryFiles(testCase, pack.boundaryFiles, "chrono");
end

function verifyCvctPack(testCase, pack)
    item = loadDta(testCase, pack.representativeFiles, "cvct");
    testCase.verifyGreaterThanOrEqual(numel(item.curves), 2, ...
        "CSC debug CV/CT sample should include at least two curve tables.");
    testCase.verifyTrue(isfinite(item.scanRate), ...
        "CSC debug CV/CT sample should include scan-rate metadata.");
    edge = loadDta(testCase, pack.boundaryFiles.validEdge, "cvct");
    testCase.verifyEqual(edge.scanRate, 0, ...
        "CSC edge sample should be valid CV/CT data with zero scan-rate metadata.");
    verifyMalformedFile(testCase, pack.boundaryFiles.malformed, "cvct");
end

function verifyEisPack(testCase, pack)
    item = loadDta(testCase, pack.representativeFiles, "eis");
    testCase.verifyGreaterThan(item.n, 10, ...
        "EIS debug sample should include a representative ZCURVE table.");
    testCase.verifyTrue(all(isfinite(item.Freq)), ...
        "EIS debug sample should include finite frequencies.");
    edge = loadDta(testCase, pack.boundaryFiles.validEdge, "eis");
    testCase.verifyEqual(edge.n, 8, ...
        "EIS edge sample should be valid but sparse.");
    verifyMalformedFile(testCase, pack.boundaryFiles.malformed, "eis");
end

function item = loadDta(testCase, filepath, kind)
    testCase.verifyTrue(isfile(filepath), "Debug sample file should be written.");
    [item, status] = labkit.dta.loadFile(filepath, kind);
    testCase.verifyTrue(status.ok, status.message);
end

function verifyBoundaryFiles(testCase, files, kind)
    edge = loadDta(testCase, files.validEdge, kind);
    testCase.verifyGreaterThan(edge.n, 2, ...
        "Format-valid edge sample should load through the DTA facade.");
    verifyMalformedFile(testCase, files.malformed, kind);
end

function verifyMalformedFile(testCase, filepath, kind)
    testCase.verifyTrue(isfile(filepath), "Malformed debug sample should be written.");
    [~, status] = labkit.dta.loadFile(filepath, kind);
    testCase.verifyFalse(status.ok, ...
        "Malformed debug sample should fail cleanly through the DTA facade.");
end

function cleanupFolder(folder)
    if strlength(string(folder)) > 0 && exist(char(folder), "dir") == 7
        rmdir(char(folder), "s");
    end
end
