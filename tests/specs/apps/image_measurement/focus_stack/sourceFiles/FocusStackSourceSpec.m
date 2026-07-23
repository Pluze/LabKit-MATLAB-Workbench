classdef FocusStackSourceSpec < matlab.unittest.TestCase
    %FOCUSSTACKSOURCESPEC Specify sorted supported focus image discovery.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function findsOnlySupportedImagesInDisplayNameOrder(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            imwrite(uint8(255 .* ones(8)), fullfile(folder, 'slice_b.png'));
            imwrite(uint8(128 .* ones(8)), fullfile(folder, 'slice_a.jpg'));
            writeText(fullfile(folder, 'notes.txt'), 'not an image');

            paths = focus_stack.sourceFiles.findImages(folder);

            testCase.verifyEqual(fileNames(paths), ["slice_a.jpg"; "slice_b.png"]);
        end
    end
end

function writeText(path, text)
file = fopen(path, 'w'); cleanup = onCleanup(@() fclose(file));
fprintf(file, '%s', text); clear cleanup
end

function names = fileNames(paths)
names = strings(numel(paths), 1);
for k = 1:numel(paths)
    [~, name, extension] = fileparts(char(paths(k)));
    names(k) = string(name) + string(extension);
end
end
