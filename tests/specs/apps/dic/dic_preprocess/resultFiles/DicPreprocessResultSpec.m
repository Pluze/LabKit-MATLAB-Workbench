classdef DicPreprocessResultSpec < matlab.unittest.TestCase
    %DICPREPROCESSRESULTSPEC Specify DIC image and mask file outputs.

    methods (Test, TestTags = {'Contract:result', 'Env:headless'})
        function writesCurrentImagesAndMaskAsPngFiles(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            reference = uint8([0 10; 20 30]);
            moving = uint8([30 20; 10 0]);
            mask = uint8([0 255; 255 0]);

            outputs = dic_preprocess.resultFiles.writeCurrentImages(reference, moving, folder);
            maskPath = dic_preprocess.resultFiles.writeMask(mask, fullfile(folder, 'mask.png'));

            testCase.verifyTrue(isfile(outputs.referencePath));
            testCase.verifyTrue(isfile(outputs.movingPath));
            testCase.verifyTrue(isfile(maskPath));
            testCase.verifyEqual(imread(outputs.referencePath), reference);
            testCase.verifyEqual(imread(maskPath), mask);
        end
    end
end
