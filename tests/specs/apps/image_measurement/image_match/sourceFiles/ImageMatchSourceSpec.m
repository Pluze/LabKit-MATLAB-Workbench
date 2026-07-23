classdef ImageMatchSourceSpec < matlab.unittest.TestCase
    %IMAGEMATCHSOURCESPEC Specify source and reference image decoding.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function readsCellArrayFilePanelPathsInOrder(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            source = fullfile(folder, "source.png");
            reference = fullfile(folder, "reference.png");
            imwrite(uint8(90 .* ones(8, 9, 3)), source);
            imwrite(uint8(110 .* ones(8, 9, 3)), reference);

            items = image_match.sourceFiles.readImages({source, reference});

            testCase.verifyEqual(numel(items), 2);
            testCase.verifyEqual(items(1).path, string(source));
            testCase.verifySize(items(2).image, [8 9 3]);
        end
    end
end
