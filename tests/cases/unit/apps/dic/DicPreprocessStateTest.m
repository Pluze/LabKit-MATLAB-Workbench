classdef DicPreprocessStateTest < matlab.unittest.TestCase
    %DICPREPROCESSSTATETEST Verify native V2 DIC project/cache contracts.

    methods (Test, TestTags = {'Unit'})
        function editHistoryStoresDurableStepsAndTrimsSnapshots(testCase)
            setupLabKitTestPath();
            project = baseProject();
            for k = 1:3
                project.annotations.editSteps = editStep("crop", [], ...
                    [k k 4 4], "step" + k);
                [project, appended] = ...
                    dic_preprocess.appState.appendEditHistory( ...
                    project, "step" + k, 2);
                testCase.verifyTrue(appended);
            end

            history = project.annotations.history;
            testCase.verifyEqual(numel(history), 2);
            testCase.verifyEqual(string({history.description}), ...
                ["step2" "step3"]);
            testCase.verifyEqual(history(end).editSteps.rect, [3 3 4 4]);
        end

        function maskHistoryStoresAnnotationsAndTrimsSnapshots(testCase)
            setupLabKitTestPath();
            project = baseProject();
            for k = 1:4
                project.annotations.maskImage = uint8(k);
                project.annotations.maskPoints = [k k+1];
                project = dic_preprocess.appState.appendMaskHistory( ...
                    project, "mask" + k, 3);
            end

            history = project.annotations.maskHistory;
            testCase.verifyEqual(numel(history), 3);
            testCase.verifyEqual(string({history.description}), ...
                ["mask2" "mask3" "mask4"]);
            testCase.verifyEqual(history(end).maskImage, uint8(4));
        end

        function resetForNewInputClearsDurableDerivedWork(testCase)
            setupLabKitTestPath();
            project = populatedProject();
            reset = dic_preprocess.appState.resetForNewInput(project);

            testCase.verifyEqual(reset.inputs.sources, project.inputs.sources);
            testCase.verifyEmpty(reset.annotations.editSteps);
            testCase.verifyEmpty(reset.annotations.cropRect);
            testCase.verifyEmpty(reset.annotations.maskImage);
            testCase.verifyEmpty(reset.annotations.maskPoints);
            testCase.verifyEmpty(reset.annotations.history);
        end

        function resetToOriginalsCanBeUndoneFromStepSnapshot(testCase)
            setupLabKitTestPath();
            project = populatedProject();
            [project, ~] = dic_preprocess.appState.appendEditHistory( ...
                project, "reset to originals");
            reset = dic_preprocess.appState.resetToOriginals(project);
            snapshot = reset.annotations.history(end);
            restored = dic_preprocess.appState.restoreEditSnapshot( ...
                reset, snapshot);

            testCase.verifyEmpty(reset.annotations.editSteps);
            testCase.verifyEqual(restored.annotations.editSteps, ...
                project.annotations.editSteps);
            testCase.verifyEqual(restored.annotations.maskImage, ...
                project.annotations.maskImage);
        end

        function restoreMaskSnapshotRebuildsDurableAnnotations(testCase)
            setupLabKitTestPath();
            project = baseProject();
            snapshot = struct( ...
                "maskImage", uint8([255 0]), ...
                "maskPoints", [5 6; 7 8], ...
                "description", "mask");
            project = dic_preprocess.appState.restoreMaskSnapshot( ...
                project, snapshot);

            testCase.verifyEqual(project.annotations.maskImage, uint8([255 0]));
            testCase.verifyEqual(project.annotations.maskPoints, [5 6; 7 8]);
        end

        function cacheReportsImagePairWithoutPollutingProject(testCase)
            setupLabKitTestPath();
            project = baseProject();
            cache = dic_preprocess.analysisRun.replayEditSteps( ...
                uint8(1), [], project.annotations.editSteps);
            testCase.verifyFalse(dic_preprocess.appState.hasImagePair(cache));
            cache.movingImage = uint8(2);
            cache.currentMovingImage = uint8(2);
            testCase.verifyTrue(dic_preprocess.appState.hasImagePair(cache));
            testCase.verifyFalse(isfield(project.inputs, 'referenceImage'));
        end

        function maskCanvasInitializesFromReferenceSize(testCase)
            setupLabKitTestPath();
            emptyCanvas = dic_preprocess.appState.maskCanvas( ...
                [], zeros(3, 4, 3, 'uint8'));
            existingCanvas = dic_preprocess.appState.maskCanvas( ...
                uint8([0 255]), zeros(3, 4));

            testCase.verifyEqual(emptyCanvas, zeros(3, 4, 'uint8'));
            testCase.verifyEqual(existingCanvas, uint8([0 255]));
        end

        function applyBoundaryToMaskAddsAndSubtractsCanvas(testCase)
            setupLabKitTestPath();
            reference = zeros(3, 4, 'uint8');
            boundary = uint8([0 255 0 0; 0 255 255 0; 0 0 0 0]);
            existing = uint8([255 0 0 0; 0 255 0 0; 0 0 0 0]);

            added = dic_preprocess.appState.applyBoundaryToMask([], ...
                reference, boundary, 'add');
            subtracted = dic_preprocess.appState.applyBoundaryToMask(existing, ...
                reference, boundary, 'subtract');

            testCase.verifyEqual(added, boundary);
            testCase.verifyEqual(subtracted, ...
                uint8([255 0 0 0; 0 0 0 0; 0 0 0 0]));
        end
    end
end

function project = baseProject()
    project = dic_preprocess.appLifecycle.createProject();
end

function project = populatedProject()
    project = baseProject();
    project.inputs.sources = sourceRecord("referenceImage", "reference.png");
    project.annotations.editSteps = editStep( ...
        "crop", [], [1 1 2 2], "crop");
    project.annotations.cropRect = [1 1 2 2];
    project.annotations.maskImage = uint8([0 255]);
    project.annotations.maskPoints = [1 2; 3 4; 5 6];
end

function step = editStep(kind, transform, rect, description)
    step = struct( ...
        "kind", string(kind), ...
        "transform", transform, ...
        "rect", rect, ...
        "description", string(description));
end

function source = sourceRecord(id, filepath)
    [~, name, extension] = fileparts(filepath);
    source = struct( ...
        "id", string(id), ...
        "required", true, ...
        "role", "reference", ...
        "reference", struct( ...
            "schemaVersion", 1, ...
            "relativePath", "", ...
            "originalPath", string(filepath), ...
            "fileName", string(name) + string(extension)));
end
