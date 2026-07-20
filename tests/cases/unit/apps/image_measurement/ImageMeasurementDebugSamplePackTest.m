classdef ImageMeasurementDebugSamplePackTest < matlab.unittest.TestCase
    %IMAGEMEASUREMENTDEBUGSAMPLEPACKTEST Verify image app debug sample packs.

    methods (Test, TestTags = {'Unit'})
        function image_measurement_debug_sample_packs_read_through_app_io(testCase)
            setupLabKitTestPath();
            root = string(tempname);
            cleanup = onCleanup(@() cleanupFolder(root));
            debug = labkit.app.diagnostic.SampleContext(root);

            batch = batch_crop.debug.writeSamplePack(debug);
            items = batch_crop.sourceFiles.readItems([ ...
                artifactPath(debug, batch, "sourceA"); ...
                artifactPath(debug, batch, "sourceB")]);
            testCase.verifyEqual(numel(items), 2);
            verifyThrows(testCase, @() imread(char( ...
                artifactPath(debug, batch, "malformed"))), ...
                "Malformed batch-crop image should fail through imread.");

            focus = focus_stack.debug.writeSamplePack(debug);
            focusImages = focus_stack.sourceFiles.readImages([ ...
                artifactPath(debug, focus, "image1"); ...
                artifactPath(debug, focus, "image2"); ...
                artifactPath(debug, focus, "image3"); ...
                artifactPath(debug, focus, "image4")]);
            testCase.verifyEqual(numel(focusImages), 4);
            verifyThrows(testCase, @() imread(char( ...
                artifactPath(debug, focus, "malformed"))), ...
                "Malformed focus-stack image should fail through imread.");

            enhance = image_enhance.debug.writeSamplePack(debug);
            enhanceItems = image_enhance.sourceFiles.readImages([ ...
                artifactPath(debug, enhance, "uneven"); ...
                artifactPath(debug, enhance, "colorCast")]);
            testCase.verifyEqual(numel(enhanceItems), 2);
            testCase.verifyFalse(isempty(imread(char( ...
                artifactPath(debug, enhance, "lowContrast")))));

            match = image_match.debug.writeSamplePack(debug);
            reference = image_match.sourceFiles.readImages( ...
                artifactPath(debug, match, "reference"));
            sources = image_match.sourceFiles.readImages([ ...
                artifactPath(debug, match, "warm"); ...
                artifactPath(debug, match, "dim")]);
            testCase.verifyEqual(numel(reference), 1);
            testCase.verifyEqual(numel(sources), 2);

            curve = curvature.debug.writeSamplePack(debug);
            testCase.verifyFalse(isempty(imread(char( ...
                artifactPath(debug, curve, "arc")))));
            testCase.verifyFalse(isempty(imread(char( ...
                artifactPath(debug, curve, "lowContrast")))));

            flir = flir_thermal.debug.writeSamplePack(debug);
            [thermalItems, report] = flir_thermal.sourceFiles.readImages([ ...
                artifactPath(debug, flir, "warm"); ...
                artifactPath(debug, flir, "cool")]);
            testCase.verifyEqual(report.loaded, 2);
            testCase.verifyEqual(numel(thermalItems), 2);
            [~, edgeReport] = flir_thermal.sourceFiles.readImages( ...
                artifactPath(debug, flir, "lowContrast"));
            testCase.verifyEqual(edgeReport.loaded, 1);
            [~, badReport] = flir_thermal.sourceFiles.readImages( ...
                artifactPath(debug, flir, "plainJpeg"));
            testCase.verifyEqual(badReport.loaded, 0);

            video = video_marker.debug.writeSamplePack(debug);
            testCase.verifyClass(video, "labkit.app.diagnostic.SamplePack");
            [reader, info] = video_marker.videoSource.openVideo( ...
                artifactPath(debug, video, "video"));
            frame = video_marker.videoSource.readFrame(reader, 1);
            testCase.verifyEqual(info.frameCount, 6);
            testCase.verifySize(frame, [72 96 3]);
            clear reader
            clear cleanup
        end
    end
end

function filepath = artifactPath(context, pack, id)
ids = string(cellfun(@(value) value.Id, pack.Artifacts, ...
    "UniformOutput", false));
index = find(ids == string(id), 1);
assert(~isempty(index), "Expected diagnostic artifact %s.", id);
parts = cellstr(split(pack.Artifacts{index}.RelativePath, "/"));
filepath = string(fullfile(char(context.ArtifactFolder), parts{:}));
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
