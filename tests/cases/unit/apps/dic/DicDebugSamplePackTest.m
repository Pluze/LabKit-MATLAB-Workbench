classdef DicDebugSamplePackTest < matlab.unittest.TestCase
    %DICDEBUGSAMPLEPACKTEST Verify DIC debug sample packs.

    methods (Test, TestTags = {'Unit'})
        function dic_debug_sample_packs_read_through_app_io(testCase)
            setupLabKitTestPath();
            root = string(tempname);
            cleanup = onCleanup(@() cleanupFolder(root));
            mkdir(char(root));
            debug = labkit.ui.debug.context("dic_debug_sample_test", struct( ...
                "logFile", fullfile(char(root), "trace.log")));

            pre = dic_preprocess.debug.writeSamplePack(debug);
            ref = imread(char(pre.representativeFiles.reference));
            moving = imread(char(pre.representativeFiles.moving));
            testCase.verifySize(ref, size(moving), ...
                "DIC preprocess representative pair should have matching dimensions.");
            verifyThrows(testCase, @() imread(char(pre.boundaryFiles.malformedImage)), ...
                "Malformed DIC image should fail through imread.");

            post = dic_postprocess.debug.writeSamplePack(debug);
            strain = dic_postprocess.sourceFiles.loadNcorrStrain(char(post.representativeFiles.mat));
            testCase.verifyTrue(isfield(strain, "exx") && isfield(strain, "eyy"));
            testCase.verifySize(imread(char(post.representativeFiles.reference)), ...
                size(imread(char(post.representativeFiles.mask))));
            edge = dic_postprocess.sourceFiles.loadNcorrStrain(char(post.boundaryFiles.validEdgeSparseRoiMat));
            testCase.verifyTrue(any(edge.roiMask(:)), ...
                "DIC postprocess edge MAT should include a readable sparse ROI.");
            verifyThrows(testCase, ...
                @() dic_postprocess.sourceFiles.loadNcorrStrain(char(post.boundaryFiles.malformedMissingStrainsMat)), ...
                "Malformed DIC MAT should fail through app IO.");
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
