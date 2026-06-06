classdef DicPostprocessIoExportTest < matlab.unittest.TestCase
    %DICPOSTPROCESSIOEXPORTTEST Verify DIC postprocess IO and export helpers.

    methods (Test, TestTags = {'Unit'})
        function loadNcorrStrainReadsExpectedFields(testCase)
            setupLabKitTestPath();

            outDir = tempname;
            mkdir(outDir);
            cleanup = onCleanup(@() cleanupFolder(outDir)); %#ok<NASGU>
            matPath = fullfile(outDir, 'synthetic_dic.mat');
            data_dic_save = struct();
            data_dic_save.strains = struct();
            data_dic_save.strains.plot_exx_ref_formatted = [1 2; 3 4];
            data_dic_save.strains.plot_eyy_ref_formatted = [5 6; 7 8];
            data_dic_save.strains.roi_ref_formatted = struct( ...
                'mask', logical([1 0; 0 1]));
            save(matPath, 'data_dic_save');

            strain = dic_postprocess.io.loadNcorrStrain(matPath);

            testCase.verifyEqual(strain.exx, data_dic_save.strains.plot_exx_ref_formatted);
            testCase.verifyEqual(strain.eyy, data_dic_save.strains.plot_eyy_ref_formatted);
            testCase.verifyEqual(strain.roiMask, data_dic_save.strains.roi_ref_formatted.mask);
        end

        function exportHelpersCreateOutputFiles(testCase)
            setupLabKitTestPath();

            outDir = tempname;
            mkdir(outDir);
            cleanup = onCleanup(@() cleanupFolder(outDir)); %#ok<NASGU>
            overlayPath = fullfile(outDir, 'overlay.png');
            colorbarPath = fullfile(outDir, 'colorbar.png');
            overlayImage = zeros(4, 4, 3);
            opts = struct();
            opts.colorRange = [-0.1 0.2];
            opts.colormap = jet(8);
            opts.exportResolution = 96;

            dic_postprocess.export.exportOverlayFigure( ...
                overlayImage, 'EXX', opts.colorRange, opts.exportResolution, overlayPath);
            dic_postprocess.export.exportStrainColorbar(opts, colorbarPath);

            testCase.verifyTrue(isfile(overlayPath));
            testCase.verifyTrue(isfile(colorbarPath));
            testCase.verifyGreaterThan(dir(overlayPath).bytes, 0);
            testCase.verifyGreaterThan(dir(colorbarPath).bytes, 0);
        end
    end
end

function cleanupFolder(folder)
    if isfolder(folder)
        rmdir(folder, 's');
    end
end
