classdef FocusStackWorkflowSpec < matlab.unittest.TestCase
    %FOCUSSTACKWORKFLOWSPEC Specify focused image fusion and export workflow.

    methods (Test, TestTags = {'Contract:presentation', 'Env:hidden-gui'})
        function loadsFusesExportsAndRestoresASyntheticStack(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            first = fullfile(folder, "near.png");
            second = fullfile(folder, "far.png");
            output = fullfile(folder, "fused.png");
            writeStack(first, second);
            backend = struct( ...
                "chooseOutputFile", @(~, ~) labkit.app.dialog.Choice(output), ...
                "alert", @(~, ~) []);
            definition = focus_stack.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createMatlabRuntime( ...
                definition, [], backend, journal);
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();

            runtime.applyFileSelection("sourceImages", [string(first); string(second)], [1 2]);
            runtime.invokeAction("runFocusStack");
            runtime.invokeAction("exportFused");

            testCase.verifyTrue(runtime.State.session.cache.result.ok);
            testCase.verifyNotEmpty(findall(figureValue, "Tag", "preview.fused").Children);
            testCase.verifyNotEmpty(findall(figureValue, "Tag", "preview.focusMap").Children);
            testCase.verifyTrue(isfile(output));
            clear cleanup
        end
    end
end

function writeStack(first, second)
[x, y] = meshgrid(1:40, 1:32);
base = uint8(120 + 80 .* sin(.5 .* x) .* cos(.4 .* y));
imwrite(base, first);
imwrite(circshift(base, [0 1]), second);
end
