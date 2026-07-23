classdef DicPostprocessSourceSpec < matlab.unittest.TestCase
    %DICPOSTPROCESSSOURCESPEC Specify decoded DIC source-cache behavior.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function readsNcorrStrainAndOptionalImageInputs(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            matPath = fullfile(folder, "strain.mat");
            referencePath = fullfile(folder, "reference.png");
            maskPath = fullfile(folder, "mask.png");
            data_dic_save = struct("strains", struct( ...
                "plot_exx_ref_formatted", [1 2; 3 4], ...
                "plot_eyy_ref_formatted", [5 6; 7 8], ...
                "roi_ref_formatted", struct("mask", logical([1 0; 0 1]))));
            save(matPath, "data_dic_save");
            imwrite(uint8(reshape(1:12, [2 2 3])), referencePath);
            imwrite(uint8(255 .* logical([1 0; 0 1])), maskPath);

            cache = dic_postprocess.sourceFiles.loadProjectInputs(struct( ...
                "dicMat", matPath, "referenceImage", referencePath, ...
                "maskImage", maskPath), true);

            testCase.verifyEqual(cache.strain.exx, data_dic_save.strains.plot_exx_ref_formatted);
            testCase.verifyEqual(cache.strain.eyy, data_dic_save.strains.plot_eyy_ref_formatted);
            testCase.verifyEqual(cache.strain.roiMask, data_dic_save.strains.roi_ref_formatted.mask);
            testCase.verifySize(cache.referenceImage, [2 2 3]);
            testCase.verifyEqual(cache.maskImage, uint8(255 .* logical([1 0; 0 1])));
        end
    end
end
