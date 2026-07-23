classdef DicPostprocessResultSpec < matlab.unittest.TestCase
    %DICPOSTPROCESSRESULTSPEC Specify deterministic DIC overlay output.

    methods (Test, TestTags = {'Contract:result', 'Env:headless'})
        function writesAClampedOverlayAndDerivesTheLastDimensionTag(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            path = fullfile(folder, "overlay.png");
            image = zeros(4, 4, 3);
            image(2:3, 2:3, 1) = 2;

            dic_postprocess.resultFiles.exportOverlayImage(image, path);

            testCase.verifyTrue(isfile(path));
            testCase.verifySize(imread(path), [4 4 3]);
            testCase.verifyEqual(dic_postprocess.resultFiles.tagFromPath( ...
                "run_0.5mm_repeat_1.25mm.mat"), "1.25mm");
            testCase.verifyEqual(dic_postprocess.resultFiles.tagFromPath( ...
                "run_without_dimension.mat"), "unknown_mm");
        end
    end
end
