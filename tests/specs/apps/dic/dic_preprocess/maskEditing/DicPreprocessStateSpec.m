classdef DicPreprocessStateSpec < matlab.unittest.TestCase
    %DICPREPROCESSSTATESPEC Specify recoverable DIC edit and mask state.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function boundsEditAndMaskHistoryWhilePreservingLatestSnapshots(testCase)
            project = dic_preprocess.definition().ProjectSchema.Create();
            for k = 1:3
                project.annotations.editSteps = editStep(k);
                [project, appended] = dic_preprocess.editHistory.appendEditHistory( ...
                    project, "step" + k, 2);
                testCase.verifyTrue(appended);
            end
            for k = 1:4
                project.annotations.maskImage = uint8(k);
                project.annotations.maskPoints = [k k + 1];
                project = dic_preprocess.maskEditing.appendMaskHistory( ...
                    project, "mask" + k, 3);
            end

            testCase.verifyEqual(numel(project.annotations.history), 2);
            testCase.verifyEqual(project.annotations.history(end).editSteps.rect, [3 3 4 4]);
            testCase.verifyEqual(numel(project.annotations.maskHistory), 3);
            testCase.verifyEqual(project.annotations.maskHistory(end).maskImage, uint8(4));
        end

        function appliesAndRestoresMaskAnnotationsWithoutSessionPixels(testCase)
            project = dic_preprocess.definition().ProjectSchema.Create();
            boundary = uint8([0 255 0 0; 0 255 255 0; 0 0 0 0]);
            existing = uint8([255 0 0 0; 0 255 0 0; 0 0 0 0]);
            subtracted = dic_preprocess.maskEditing.applyBoundaryToMask( ...
                existing, zeros(3, 4, 'uint8'), boundary, 'subtract');
            snapshot = struct("maskImage", uint8([255 0]), ...
                "maskPoints", [5 6; 7 8], "description", "mask");
            restored = dic_preprocess.maskEditing.restoreMaskSnapshot(project, snapshot);

            testCase.verifyEqual(subtracted, uint8([255 0 0 0; 0 0 0 0; 0 0 0 0]));
            testCase.verifyEqual(restored.annotations.maskImage, uint8([255 0]));
            testCase.verifyEqual(restored.annotations.maskPoints, [5 6; 7 8]);
        end
    end
end

function step = editStep(value)
step = struct("kind", "crop", "transform", [], "rect", [value value 4 4], ...
    "description", "step" + value);
end
