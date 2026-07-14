classdef PortableFileReferenceTest < matlab.unittest.TestCase
    %PORTABLEFILEREFERENCETEST Verify movable external-file references.

    methods (Test, TestTags = {'Unit'})
        function relative_reference_survives_directory_tree_move(testCase)
            setupLabKitTestPath();
            sourceRoot = string(tempname);
            movedRoot = string(tempname);
            mkdir(fullfile(sourceRoot, "state"));
            mkdir(fullfile(sourceRoot, "source"));
            cleanup = onCleanup(@() cleanupFolders(sourceRoot, movedRoot));
            anchorFile = fullfile(sourceRoot, "state", "project.mat");
            targetFile = fullfile(sourceRoot, "source", "capture.dat");
            touchFile(anchorFile);
            touchFile(targetFile);

            reference = labkit.ui.runtime.createPortableFileReference( ...
                anchorFile, targetFile);
            testCase.verifyEqual(reference.schemaVersion, 1);
            testCase.verifyEqual(reference.relativePath, "../source/capture.dat");
            movefile(sourceRoot, movedRoot);

            movedAnchor = fullfile(movedRoot, "state", "project.mat");
            movedTarget = fullfile(movedRoot, "source", "capture.dat");
            [resolved, matchKind] = ...
                labkit.ui.runtime.resolvePortableFileReference( ...
                movedAnchor, reference);
            [~, attributes] = fileattrib(char(movedTarget));
            testCase.verifyEqual(resolved, string(attributes.Name));
            testCase.verifyEqual(matchKind, "relative");
        end

        function unresolved_reference_returns_explicit_none(testCase)
            setupLabKitTestPath();
            reference = labkit.ui.runtime.createPortableFileReference( ...
                fullfile(tempdir, "missing", "project.mat"), ...
                fullfile(tempdir, "missing", "capture.dat"));
            [resolved, matchKind] = ...
                labkit.ui.runtime.resolvePortableFileReference( ...
                fullfile(tempdir, "other", "project.mat"), reference);
            testCase.verifyEqual(resolved, "");
            testCase.verifyEqual(matchKind, "none");
        end

        function malformed_reference_falls_back_to_manual_selection(testCase)
            setupLabKitTestPath();
            folder = string(tempname);
            mkdir(folder);
            cleanup = onCleanup(@() removeFolder(folder));
            selectedFile = fullfile(folder, "replacement.dat");
            touchFile(selectedFile);
            malformed = struct('relativePath', struct('bad', true));

            [resolved, result] = ...
                labkit.ui.runtime.resolveOrPromptForFileReference( ...
                fullfile(folder, "project.mat"), malformed, ...
                'ReferenceLabel', "primary source", 'Chooser', @chooseFile);
            [~, attributes] = fileattrib(char(selectedFile));
            testCase.verifyEqual(resolved, string(attributes.Name));
            testCase.verifyEqual(result.matchKind, "selected");
            testCase.verifyTrue(result.prompted);
            testCase.verifyTrue(result.pathIssue);

            function [file, selectedFolder] = chooseFile(~, titleText, ~)
                testCase.verifySubstring(string(titleText), "primary source");
                [selectedFolder, name, extension] = fileparts(selectedFile);
                file = char(name + extension);
                selectedFolder = char(selectedFolder);
            end
        end
    end
end

function touchFile(pathValue)
    fileId = fopen(pathValue, 'w');
    assert(fileId >= 0, 'Could not create portable-reference fixture.');
    fclose(fileId);
end

function cleanupFolders(first, second)
    removeFolder(first);
    removeFolder(second);
end

function removeFolder(folder)
    if exist(folder, 'dir') == 7
        rmdir(folder, 's');
    end
end
