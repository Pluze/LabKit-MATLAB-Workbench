classdef ImageMeasurementDebugSamplePackTest < matlab.unittest.TestCase
    %IMAGEMEASUREMENTDEBUGSAMPLEPACKTEST Verify image app debug sample packs.

    methods (Test, TestTags = {'Unit'})
        function image_measurement_debug_sample_packs_read_through_app_io(testCase)
            setupLabKitTestPath();
            root = string(tempname);
            cleanup = onCleanup(@() cleanupFolder(root));
            mkdir(char(root));
            debug = labkit.ui.diag.createContext("image_debug_sample_test", struct( ...
                "logFile", fullfile(char(root), "trace.log")));

            batch = batch_crop.debug.writeSamplePack(debug);
            items = batch_crop.appState.readItems(batch.representativeFiles);
            testCase.verifyEqual(numel(items), 2);
            verifyThrows(testCase, @() imread(char(batch.boundaryFiles.malformed)), ...
                "Malformed batch-crop image should fail through imread.");

            focus = focus_stack.debug.writeSamplePack(debug);
            focusImages = focus_stack.sourceFiles.readImages(focus.representativeFiles);
            testCase.verifyEqual(numel(focusImages), 4);
            verifyThrows(testCase, @() imread(char(focus.boundaryFiles.malformed)), ...
                "Malformed focus-stack image should fail through imread.");

            enhance = image_enhance.debug.writeSamplePack(debug);
            enhanceItems = image_enhance.sourceFiles.readImages(enhance.representativeFiles);
            testCase.verifyEqual(numel(enhanceItems), 2);
            testCase.verifyFalse(isempty(imread(char(enhance.boundaryFiles.validEdge))));

            match = image_match.debug.writeSamplePack(debug);
            reference = image_match.sourceFiles.readImages(match.referenceFile);
            sources = image_match.sourceFiles.readImages(match.representativeFiles);
            testCase.verifyEqual(numel(reference), 1);
            testCase.verifyEqual(numel(sources), 2);

            curve = curvature.debug.writeSamplePack(debug);
            testCase.verifyFalse(isempty(imread(char(curve.representativeFiles))));
            testCase.verifyFalse(isempty(imread(char(curve.boundaryFiles.validEdge))));

            flir = flir_thermal.debug.writeSamplePack(debug);
            [thermalItems, report] = flir_thermal.sourceFiles.readImages(flir.representativeFiles);
            testCase.verifyEqual(report.loaded, 2);
            testCase.verifyEqual(numel(thermalItems), 2);
            [~, edgeReport] = flir_thermal.sourceFiles.readImages(flir.boundaryFiles.validEdgeLowContrast);
            testCase.verifyEqual(edgeReport.loaded, 1);
            [~, badReport] = flir_thermal.sourceFiles.readImages(flir.boundaryFiles.malformedPlainJpeg);
            testCase.verifyEqual(badReport.loaded, 0);
        end
    end
end

function verifyThrows(testCase, fcn, message)
    didThrow = false;
    try
        fcn();
    catch
        didThrow = true;
    end
    testCase.verifyTrue(didThrow, message);
end

function cleanupFolder(folder)
    if strlength(string(folder)) > 0 && exist(char(folder), "dir") == 7
        rmdir(char(folder), "s");
    end
end
