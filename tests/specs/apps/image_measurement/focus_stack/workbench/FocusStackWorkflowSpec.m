classdef FocusStackWorkflowSpec < matlab.unittest.TestCase
    %FOCUSSTACKWORKFLOWSPEC Specify focused image fusion and export workflow.

    methods (Test, TestTags = {'Contract:workflow', 'Env:hidden-gui'})
        function loadsFusesExportsAndRestoresASyntheticStack(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            first = fullfile(folder, "near.png");
            second = fullfile(folder, "far.png");
            output = fullfile(folder, "fused.png");
            focusMap = fullfile(folder, "focus-map.png");
            summary = fullfile(folder, "summary.csv");
            writeStack(first, second);
            backend = struct( ...
                "chooseInputFolder", @(~) labkit.app.dialog.Choice(folder), ...
                "chooseOutputFile", @(~, defaultPath) labkit.app.dialog.Choice( ...
                    outputPath(defaultPath, output, focusMap, summary)), ...
                "alert", @(~, ~) []);
            definition = focus_stack.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createMatlabRuntime( ...
                definition, [], backend, journal);
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();

            runtime.invokeAction("sourceFolderChosen");
            runtime.applyFileSelection("sourceImages", ...
                [string(first); string(second)], [1 2]);
            runtime.applyControlValue("fusionPreset", "Crisp");
            runtime.applyControlValue("autoRegister", true);
            runtime.applyControlValue("focusWindow", 5);
            runtime.applyControlValue("smoothRadius", 1);
            runtime.applyControlValue("uncertainBlend", 10);
            runtime.invokeAction("runFocusStack");
            runtime.invokeAction("exportFused");
            runtime.invokeAction("exportFocusMap");
            runtime.invokeAction("exportSummary");

            testCase.verifyTrue(runtime.State.session.cache.result.ok);
            result = runtime.State.session.cache.result;
            testCase.verifyEqual([result.focusWindow, result.smoothRadius, ...
                100 .* result.minConfidence], [5, 1, 10]);
            testCase.verifySubstring(join( ...
                runtime.State.project.results.registrationLines, newline), ...
                "Registered image");
            testCase.verifyEqual( ...
                runtime.State.session.cache.plotViewRevision, 1);
            testCase.verifyNotEmpty(findall(figureValue, "Tag", "preview.fused").Children);
            testCase.verifyNotEmpty(findall(figureValue, "Tag", "preview.focusMap").Children);
            fusedAxes = findall(figureValue, "Tag", "preview.fused");
            fusedPixels = findall(fusedAxes, "Type", "image");
            testCase.verifyEqual(fusedPixels.CData, repmat(result.fused, 1, 1, 3));
            quality = findall(figureValue, "Tag", "preview.confidence");
            pixels = findall(quality, "Type", "image");
            % Oracle: display the computed quality matrix on its fixed scale;
            % a normalized-per-image or stale map would change these values.
            testCase.verifyEqual(pixels.CData, result.confidence);
            testCase.verifyEqual(quality.CLim, [0 1]);
            capture = labkittest.nativeGraphicsCapability("interface-capture");
            evidencePath = labkittest.visualEvidencePath("focus-quality", ".png");
            if capture.Available
                exportapp(figureValue, evidencePath);
                testCase.verifyTrue(isfile(evidencePath));
            else
                testCase.verifyError(@() exportapp(figureValue, evidencePath), capture.ErrorIdentifier);
                testCase.verifyFalse(isfile(evidencePath));
            end
            runtime.applyControlValue("focusWindow", 7);
            testCase.verifyEmpty(findall(quality, "Type", "image"));
            testCase.verifyFalse(runtime.State.session.cache.result.ok);
            testCase.verifyTrue(isfile(output));
            testCase.verifyTrue(isfile(focusMap));
            testCase.verifyTrue(isfile(summary));
            clear cleanup
        end
    end
end

function path = outputPath(defaultPath, fusedPath, focusMapPath, summaryPath)
defaultPath = string(defaultPath);
if contains(defaultPath, "stack_map")
    path = focusMapPath;
elseif endsWith(defaultPath, ".csv")
    path = summaryPath;
else
    path = fusedPath;
end
end

function writeStack(first, second)
[x, y] = meshgrid(1:40, 1:32);
base = uint8(120 + 80 .* sin(.5 .* x) .* cos(.4 .* y));
imwrite(base, first);
imwrite(circshift(base, [0 1]), second);
end
