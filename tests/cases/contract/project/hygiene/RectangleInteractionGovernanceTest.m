classdef RectangleInteractionGovernanceTest < matlab.unittest.TestCase
    %RECTANGLEINTERACTIONGOVERNANCETEST Guard draggable rectangle behavior.

    methods (Test, TestTags = {'Integration', 'Style'})
        function appRectanglesUseSharedInteractionContracts(testCase)
            root = setupLabKitTestPath();
            files = sourceFiles(root);
            directFiles = filesWithDirectRectangleCalls(root, files);
            expected = [
                "+labkit/+ui/+interaction/rectangleEditor.m"
                "+labkit/+ui/+runtime/private/reconcileV2Interactions.m"
                "apps/dic/dic_preprocess/+dic_preprocess/+userInterface/renderPreviewImage.m"
                "apps/image_measurement/image_enhance/+image_enhance/+userInterface/renderImagePreview.m"
                "apps/image_measurement/flir_thermal/+flir_thermal/+userInterface/drawTemperatureReadings.m"
            ];
            testCase.verifyEqual(sort(directFiles), sort(expected), ...
                ['Interactive app rectangles must use rectangleEditor or an ' ...
                'interaction-runtime drag session. Direct rectangle primitives ' ...
                'require an explicit governance review.']);

            appDirectFiles = directFiles(startsWith(directFiles, "apps/"));
            for k = 1:numel(appDirectFiles)
                source = fileread(fullfile(root, char(appDirectFiles(k))));
                testCase.verifyTrue(contains(source, "'HitTest', 'off'") && ...
                    contains(source, "'PickableParts', 'none'"), ...
                    appDirectFiles(k) + ...
                    " must keep direct rectangle overlays non-pickable.");
            end
        end

        function knownInteractiveWorkflowsUseEditorOrDragSession(testCase)
            root = setupLabKitTestPath();
            controlledUsers = [
                "apps/dic/dic_preprocess/+dic_preprocess/+userInterface/presentWorkbench.m"
                "apps/image_measurement/batch_crop/+batch_crop/+userInterface/presentWorkbench.m"
                "apps/image_measurement/image_enhance/+image_enhance/+userInterface/presentWorkbench.m"
            ];
            for k = 1:numel(controlledUsers)
                source = fileread(fullfile(root, char(controlledUsers(k))));
                testCase.verifyTrue(contains(source, '"Kind", "rectangle"'), ...
                    controlledUsers(k) + ...
                    " must declare a Runtime V2 controlled rectangle.");
            end

            flirPresenter = fileread(fullfile(root, ...
                'apps/image_measurement/flir_thermal/+flir_thermal', ...
                '+userInterface/presentWorkbench.m'));
            testCase.verifyTrue(contains(flirPresenter, ...
                '"Kind", "regionSelection"'), ...
                ['FLIR point and ROI reads must use the Runtime V2 ' ...
                'controlled region-selection contract.']);
        end
    end
end

function files = sourceFiles(root)
    [status, output] = system(sprintf([ ...
        'git -C "%s" ls-files --cached --others --exclude-standard ' ...
        '+labkit apps'], root));
    assert(status == 0, 'Could not list rectangle source files.');
    files = string(splitlines(strtrim(output)));
    files = files(endsWith(files, ".m"));
    existsNow = arrayfun(@(file) isfile(fullfile(root, file)), files);
    files = files(existsNow);
end

function files = filesWithDirectRectangleCalls(root, candidates)
    files = strings(0, 1);
    pattern = '(?<![A-Za-z0-9_.])rectangle\s*\(';
    for k = 1:numel(candidates)
        source = fileread(fullfile(root, char(candidates(k))));
        if ~isempty(regexp(source, pattern, 'once'))
            files(end + 1, 1) = replace(candidates(k), "\", "/");
        end
    end
end
