classdef ElectrochemDebugSamplePackTest < matlab.unittest.TestCase
    %ELECTROCHEMDEBUGSAMPLEPACKTEST Verify electrochem debug sample packs.

    methods (Test, TestTags = {'Unit'})
        function electrochem_debug_sample_packs_load_through_dta_facade(testCase)
            setupLabKitTestPath();
            fixtureRoot = string(tempname);
            cleanup = onCleanup(@() cleanupFolder(fixtureRoot));
            context = labkit.app.diagnostic.SampleContext(fixtureRoot);

            verifyChronoOverlayPack(testCase, context, ...
                chrono_overlay.debug.writeSamplePack(context));
            verifyChronoPack(testCase, context, ...
                cic.debug.writeSamplePack(context), "weakResponse");
            verifyChronoPack(testCase, context, ...
                vt_resistance.debug.writeSamplePack(context), "lowResistance");
            verifyCvctPack(testCase, context, ...
                csc.debug.writeSamplePack(context));
            verifyEisPack(testCase, context, ...
                eis.debug.writeSamplePack(context));
        end
    end
end

function verifyChronoOverlayPack(testCase, context, pack)
    verifyTypedPack(testCase, pack);
    representativeFiles = [ ...
        artifactPath(context, pack, "currentPulse"), ...
        artifactPath(context, pack, "voltagePulse")];
    testCase.verifyEqual(numel(representativeFiles), 2, ...
        "Chrono overlay debug pack should provide two representative chrono files.");
    for k = 1:numel(representativeFiles)
        item = loadDta(testCase, representativeFiles(k), "chrono");
        testCase.verifyGreaterThan(numel(item.t), 20, ...
            "Chrono overlay samples should contain tabular time-series rows.");
        testCase.verifyTrue(any(isfinite(item.Vf)) && any(isfinite(item.Im)), ...
            "Chrono overlay samples should include finite voltage and current data.");
    end
    verifyBoundaryFiles(testCase, context, pack, "noPulse", "chrono");
end

function verifyChronoPack(testCase, context, pack, edgeId)
    verifyTypedPack(testCase, pack);
    item = loadDta(testCase, ...
        artifactPath(context, pack, "representative"), "chrono");
    testCase.verifyGreaterThan(numel(item.t), 20, ...
        "Chrono debug samples should contain representative rows.");
    testCase.verifyTrue(any(abs(item.Im) > 0), ...
        "Chrono debug samples should include current response data.");
    verifyBoundaryFiles(testCase, context, pack, edgeId, "chrono");
end

function verifyCvctPack(testCase, context, pack)
    verifyTypedPack(testCase, pack);
    item = loadDta(testCase, ...
        artifactPath(context, pack, "representative"), "cvct");
    testCase.verifyGreaterThanOrEqual(numel(item.curves), 2, ...
        "CSC debug CV/CT sample should include at least two curve tables.");
    testCase.verifyTrue(isfinite(item.scanRate), ...
        "CSC debug CV/CT sample should include scan-rate metadata.");
    edge = loadDta(testCase, ...
        artifactPath(context, pack, "zeroScanRate"), "cvct");
    testCase.verifyEqual(edge.scanRate, 0, ...
        "CSC edge sample should be valid CV/CT data with zero scan-rate metadata.");
    verifyMalformedFile(testCase, ...
        artifactPath(context, pack, "malformed"), "cvct");
end

function verifyEisPack(testCase, context, pack)
    verifyTypedPack(testCase, pack);
    item = loadDta(testCase, ...
        artifactPath(context, pack, "representative"), "eis");
    testCase.verifyGreaterThan(item.n, 10, ...
        "EIS debug sample should include a representative ZCURVE table.");
    testCase.verifyTrue(all(isfinite(item.Freq)), ...
        "EIS debug sample should include finite frequencies.");
    edge = loadDta(testCase, ...
        artifactPath(context, pack, "sparse"), "eis");
    testCase.verifyEqual(edge.n, 8, ...
        "EIS edge sample should be valid but sparse.");
    verifyMalformedFile(testCase, ...
        artifactPath(context, pack, "malformed"), "eis");
end

function item = loadDta(testCase, filepath, kind)
    testCase.verifyTrue(isfile(filepath), "Debug sample file should be written.");
    [item, status] = labkit.dta.loadFile(filepath, kind);
    testCase.verifyTrue(status.ok, status.message);
end

function verifyBoundaryFiles(testCase, context, pack, edgeId, kind)
    edge = loadDta(testCase, artifactPath(context, pack, edgeId), kind);
    testCase.verifyGreaterThan(edge.n, 2, ...
        "Format-valid edge sample should load through the DTA facade.");
    verifyMalformedFile(testCase, ...
        artifactPath(context, pack, "malformed"), kind);
end

function verifyTypedPack(testCase, pack)
testCase.verifyClass(pack, "labkit.app.diagnostic.SamplePack");
testCase.verifyNotEmpty(pack.InitialProject.inputs.sources);
end

function filepath = artifactPath(context, pack, id)
matches = cellfun(@(artifact) artifact.Id == id, pack.Artifacts);
filepath = fullfile(context.ArtifactFolder, ...
    pack.Artifacts{matches}.RelativePath);
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
