classdef GeometryTemplatesSpec < matlab.unittest.TestCase
    % GEOMETRYTEMPLATESSPEC Invariant: shape and size templates resolve independently from per-image ROI centers.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function provesGeometryTemplates(testCase)
            template = roi_analyzer.roiTemplates.emptyTemplate();
            template.id = "template-1";
            template.name = "Shared";
            template.shape = "Rectangle";
            template.size = [9 5];
            first = roi_analyzer.roiLibrary.emptyRoi();
            first.id = "roi-1";
            first.name = "First";
            first.templateId = template.id;
            first.centerXY = [20 20];
            second = first;
            second.id = "roi-2";
            second.name = "Second";
            second.centerXY = [50 35];
            definitions = [first; second];

            before = roi_analyzer.roiTemplates.resolve( ...
                definitions, template, [80 90]);
            template.shape = "Circle";
            template.size = [15 15];
            after = roi_analyzer.roiTemplates.resolve( ...
                definitions, template, [80 90]);

            testCase.verifyEqual(vertcat(after.centerXY), ...
                vertcat(before.centerXY));
            testCase.verifyEqual(string({after.shape}), ["Circle" "Circle"]);
            testCase.verifyEqual(vertcat(after.size), [15 15; 15 15]);
            testCase.verifyNotEqual(vertcat(after.position), ...
                vertcat(before.position));
        end
    end
end
