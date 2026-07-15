classdef DicPostprocessIoExportTest < matlab.unittest.TestCase
    %DICPOSTPROCESSIOEXPORTTEST Verify DIC postprocess IO and export helpers.

    methods (Test, TestTags = {'Unit'})
        function loadNcorrStrainReadsExpectedFields(testCase)
            setupLabKitTestPath();

            outDir = tempname;
            mkdir(outDir);
            cleanup = onCleanup(@() cleanupFolder(outDir));
            matPath = fullfile(outDir, 'synthetic_dic.mat');
            data_dic_save = struct();
            data_dic_save.strains = struct();
            data_dic_save.strains.plot_exx_ref_formatted = [1 2; 3 4];
            data_dic_save.strains.plot_eyy_ref_formatted = [5 6; 7 8];
            data_dic_save.strains.roi_ref_formatted = struct( ...
                'mask', logical([1 0; 0 1]));
            save(matPath, 'data_dic_save');

            strain = dic_postprocess.sourceFiles.loadNcorrStrain(matPath);

            testCase.verifyEqual(strain.exx, data_dic_save.strains.plot_exx_ref_formatted);
            testCase.verifyEqual(strain.eyy, data_dic_save.strains.plot_eyy_ref_formatted);
            testCase.verifyEqual(strain.roiMask, data_dic_save.strains.roi_ref_formatted.mask);
        end

        function exportHelpersCreateOutputFiles(testCase)
            setupLabKitTestPath();

            outDir = tempname;
            mkdir(outDir);
            cleanup = onCleanup(@() cleanupFolder(outDir));
            overlayPath = fullfile(outDir, 'overlay.png');
            overlayImage = zeros(4, 4, 3);
            overlayImage(2:3, 2:3, 1) = 1;

            dic_postprocess.resultFiles.exportOverlayImage(overlayImage, overlayPath);

            testCase.verifyTrue(isfile(overlayPath));
            testCase.verifyGreaterThan(dir(overlayPath).bytes, 0);
            testCase.verifySize(imread(overlayPath), [4 4 3]);
        end

        function runtimeV2ProjectAndPresenterContracts(testCase)
            setupLabKitTestPath();
            definition = dic_postprocess.definition();
            testCase.verifyEqual(definition.contractVersion, 2);
            project = definition.project.Create();
            testCase.verifyTrue(definition.project.Validate(project));
            testCase.verifyEmpty(definition.project.Migrations, ...
                'Payload version 1 should not invent a legacy migration.');
            invalid = project;
            invalid.parameters.gamma = Inf;
            testCase.verifyFalse(definition.project.Validate(invalid));

            project.inputs.referenceImage = uint8(reshape(1:48, [4 4 3]));
            project.inputs.maskImage = true(4);
            project.inputs.strain = struct( ...
                'exx', zeros(4), 'eyy', ones(4), 'roiMask', true(4));
            [summary, ~, ~] = dic_postprocess.analysisRun.prepareOutputs( ...
                project.inputs, project.parameters);
            project.results.summaryTable = summary;
            session = dic_postprocess.appLifecycle.createSession(project);
            state = struct('project', project, 'session', session);
            presentation = dic_postprocess.userInterface.presentWorkbench(state);
            testCase.verifyTrue(isscalar(presentation));
            testCase.verifyGreaterThan(size( ...
                presentation.controls.resultTable.Data, 1), 0);
            testCase.verifyNotEmpty( ...
                presentation.previews.overlayAxes.Axes.exx.Model.imageData);
            testCase.verifyNotEmpty( ...
                presentation.previews.overlayAxes.Axes.eyy.Model.imageData);
        end
    end
end

function cleanupFolder(folder)
    if isfolder(folder)
        rmdir(folder, 's');
    end
end
