classdef AnchorPathTest < matlab.unittest.TestCase
    methods (Test, TestTags = {'Unit'})
        function buildsCurveAndStraightPaths(testCase)
            setupLabKitTestPath();
            points = [10 30; 30 10; 50 30];
            curve = labkit.app.interaction.interpolateAnchorPath( ...
                points, [40 60], "Style", "Curve");
            testCase.verifyGreaterThan(size(curve, 1), size(points, 1));
            testCase.verifyEqual(curve(1, :), points(1, :), ...
                'AbsTol', 1e-12);
            testCase.verifyEqual(curve(end, :), points(end, :), ...
                'AbsTol', 1e-12);

            straight = labkit.app.interaction.interpolateAnchorPath( ...
                points, [40 60], "Style", "Straight lines");
            testCase.verifyEqual(straight, points);
        end
    end
end
