classdef DicDebugSamplePackTest < matlab.unittest.TestCase
    %DICDEBUGSAMPLEPACKTEST Verify DIC debug sample packs.

    methods (Test, TestTags = {'Unit'})
        function dic_debug_sample_packs_read_through_app_io(testCase)
            setupLabKitTestPath();
            root = string(tempname);
            cleanup = onCleanup(@() cleanupFolder(root));
            context = labkit.app.diagnostic.SampleContext(root);

            pre = dic_preprocess.debug.writeSamplePack(context);
            testCase.verifyClass(pre, "labkit.app.diagnostic.SamplePack");
            testCase.verifyTrue( ...
                dic_preprocess.projectSpec().Validate(pre.InitialProject));
            ref = imread(artifactPath(context, pre, "referenceImage"));
            moving = imread(artifactPath(context, pre, "movingImage"));
            testCase.verifySize(ref, size(moving), ...
                "DIC preprocess representative pair should have matching dimensions.");
            verifyThrows(testCase, ...
                @() imread(artifactPath(context, pre, "malformedImage")), ...
                "Malformed DIC image should fail through imread.");

            post = dic_postprocess.debug.writeSamplePack(context);
            testCase.verifyClass(post, "labkit.app.diagnostic.SamplePack");
            testCase.verifyTrue( ...
                dic_postprocess.projectSpec().Validate(post.InitialProject));
            strain = dic_postprocess.sourceFiles.loadNcorrStrain( ...
                artifactPath(context, post, "strain"));
            testCase.verifyTrue(isfield(strain, "exx") && isfield(strain, "eyy"));
            testCase.verifySize( ...
                imread(artifactPath(context, post, "referenceImage")), ...
                size(imread(artifactPath(context, post, "maskImage"))));
            edge = dic_postprocess.sourceFiles.loadNcorrStrain( ...
                artifactPath(context, post, "sparseRoiStrain"));
            testCase.verifyTrue(any(edge.roiMask(:)), ...
                "DIC postprocess edge MAT should include a readable sparse ROI.");
            verifyThrows(testCase, ...
                @() dic_postprocess.sourceFiles.loadNcorrStrain( ...
                    artifactPath(context, post, "malformedStrain")), ...
                "Malformed DIC MAT should fail through app IO.");
        end

        function dic_definitions_start_from_typed_synthetic_projects(testCase)
            setupLabKitTestPath();
            root = string(tempname);
            cleanup = onCleanup(@() cleanupFolder(root));

            preprocess = startSynthetic( ...
                dic_preprocess.definition(), fullfile(root, "preprocess"));
            cleanupPreprocess = onCleanup(@() preprocess.close());
            testCase.verifyEqual( ...
                string({preprocess.State.project.inputs.sources.role}), ...
                ["referenceImage", "movingImage"]);

            postprocess = startSynthetic( ...
                dic_postprocess.definition(), fullfile(root, "postprocess"));
            cleanupPostprocess = onCleanup(@() postprocess.close());
            testCase.verifyEqual( ...
                string({postprocess.State.project.inputs.sources.role}), ...
                ["strain", "reference", "mask"]);
            clear cleanupPostprocess cleanupPreprocess cleanup
        end
    end
end

function runtime = startSynthetic(definition, folder)
options = labkit.app.diagnostic.Options( ...
    Level="verbose", ArtifactFolder=folder, Sample="synthetic");
runtime = definition.createRuntimeForTesting([], struct(), options);
end

function filepath = artifactPath(context, pack, id)
matches = cellfun(@(artifact) artifact.Id == id, pack.Artifacts);
artifact = pack.Artifacts{matches};
filepath = char(fullfile(context.ArtifactFolder, artifact.RelativePath));
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
