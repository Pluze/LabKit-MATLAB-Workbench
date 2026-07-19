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

        function documentedStandaloneExampleRuns(testCase)
            setupLabKitTestPath();
            inputs = struct( ...
                "referenceImage", zeros(16, 16, 3), ...
                "maskImage", true(16), ...
                "strain", struct( ...
                    "exx", zeros(8), ...
                    "eyy", 0.01 .* ones(8), ...
                    "roiMask", true(8)));
            parameters = struct( ...
                "alpha", 0.60, "colorMin", -0.15, "colorMax", 0.15, ...
                "oversample", 6, "smoothSigma", 0.8, "edgeTrim", 1, ...
                "brightness", 0, "contrast", 1, "gamma", 1, ...
                "saturation", 1, "redGain", 1, ...
                "greenGain", 1, "blueGain", 1);

            [summary, overlayExx, overlayEyy] = ...
                dic_postprocess.analysisRun.prepareOutputs(inputs, parameters);

            testCase.verifySize(overlayExx, [16 16 3]);
            testCase.verifySize(overlayEyy, [16 16 3]);
            testCase.verifyEqual(summary.Metric, ...
                ["Mean"; "Std"; "Median"; "Min"; "Max"]);
        end

        function appSdkProjectAndPresenterContracts(testCase)
            setupLabKitTestPath();
            folder = tempname;
            mkdir(folder);
            cleanup = onCleanup(@() cleanupFolder(folder));
            definition = dic_postprocess.definition();
            testCase.verifyClass(definition, "labkit.app.Definition");
            project = definition.ProjectSchema.Create();
            testCase.verifyTrue(definition.ProjectSchema.Validate(project));
            testCase.verifyEmpty(definition.ProjectSchema.Migrate, ...
                'Payload version 1 should not invent a migration callback.');
            invalid = project;
            invalid.parameters.gamma = Inf;
            testCase.verifyFalse(definition.ProjectSchema.Validate(invalid));

            matPath = fullfile(folder, 'project-strain.mat');
            referencePath = fullfile(folder, 'project-reference.png');
            maskPath = fullfile(folder, 'project-mask.png');
            data_dic_save = struct("strains", struct( ...
                "plot_exx_ref_formatted", zeros(4), ...
                "plot_eyy_ref_formatted", ones(4), ...
                "roi_ref_formatted", struct("mask", true(4))));
            save(matPath, 'data_dic_save');
            imwrite(uint8(reshape(1:48, [4 4 3])), referencePath);
            imwrite(uint8(255 .* true(4)), maskPath);
            project.inputs.sources = [ ...
                sourceRecord("dicMat", "strain", matPath); ...
                sourceRecord("referenceImage", "reference", referencePath); ...
                sourceRecord("maskImage", "mask", maskPath)];
            cache = dic_postprocess.sourceFiles.loadProjectInputs(struct( ...
                "dicMat", string(matPath), ...
                "referenceImage", string(referencePath), ...
                "maskImage", string(maskPath)), true);
            [summary, ~, ~] = dic_postprocess.analysisRun.prepareOutputs( ...
                cache, project.parameters);
            project.results.summaryTable = summary;
            runtime = definition.createRuntimeForTesting(project);
            runtimeCleanup = onCleanup(@() runtime.close());
            testCase.verifyClass(runtime.Presentation, ...
                "labkit.app.view.Snapshot");
            testCase.verifyNotEmpty(runtime.State.session.cache.overlayExx);
            testCase.verifyNotEmpty(runtime.State.session.cache.overlayEyy);
            testCase.verifyEqual(fieldnames(project.inputs), {'sources'}, ...
                'Durable project inputs should not duplicate decoded cache data.');
        end
    end
end

function source = sourceRecord(id, role, filepath)
    [~, name, extension] = fileparts(filepath);
    source = struct( ...
        "id", string(id), ...
        "required", true, ...
        "role", string(role), ...
        "reference", struct( ...
            "schemaVersion", 1, ...
            "relativePath", "", ...
            "originalPath", string(filepath), ...
            "fileName", string(name) + string(extension)));
end

function cleanupFolder(folder)
    if isfolder(folder)
        rmdir(folder, 's');
    end
end
