classdef ImageMatchPresentationSpec < matlab.unittest.TestCase
    %IMAGEMATCHPRESENTATIONSPEC Specify declared reference-match controls.

    methods (Test, TestTags = {'Contract:presentation', 'Env:headless'})
        function declaresReferenceSourceHistoryAndExportControls(testCase)
            plan = labkittest.inspectDefinition(image_match.definition());
            ids = string({plan.Nodes.Id});

            testCase.verifyTrue(all(ismember( ...
                ["referenceImage" "sourceImages" "applyMatch" "historyTable" "exportImages"], ids)));
        end

        function reportsOriginalOutputDimensionsRatherThanPreviewDimensions(testCase)
            item = image_match.sourceFiles.emptyItem();
            item.name = "source.png";
            item.image = zeros(260, 390, 3);
            tableData = image_match.imagePreview.presentationData.resultTableData( ...
                item, zeros(150, 225, 3), 0);

            testCase.verifyEqual(string(tableData(string(tableData(:, 1)) == "Output size", 2)), ...
                "390 x 260 px");
        end
    end
end
