classdef CleanLabKitArtifactsSpec < matlab.unittest.TestCase
    % CLEANLABKITARTIFACTSSPEC Regression: generated artifacts cleanup stays bounded and idempotent.

    methods (Test, TestTags = {'Contract:system', 'Env:headless'})
        function removesOnlyArtifactsAndReportsProgress(testCase)
            [root, cleanup] = temporaryLabKitRoot(testCase);
            artifactFile = fullfile(root, "artifacts", "reports", "report.txt");
            preservedFile = fullfile(root, "apps", "preserved.txt");
            writeFile(artifactFile, "generated");
            writeFile(preservedFile, "preserved");
            progressValues = zeros(0, 1);
            progressMessages = strings(0, 1);

            result = cleanLabKitArtifacts(root, ProgressFcn=@recordProgress);

            testCase.verifyEqual(string(fieldnames(result)), [ ...
                "root"; "removedCount"; "removedTargets"; "errors"]);
            testCase.verifyEqual(result.removedCount, 1);
            testCase.verifyEqual(result.removedTargets, "artifacts");
            testCase.verifyEmpty(result.errors);
            testCase.verifyFalse(isfolder(fullfile(root, "artifacts")));
            testCase.verifyTrue(isfile(preservedFile));
            testCase.verifyEqual(progressValues(1), 0.05);
            testCase.verifyEqual(progressValues(end), 1.00);
            testCase.verifyTrue(all(diff(progressValues) >= 0));
            testCase.verifyNotEmpty(progressMessages);

            repeated = cleanLabKitArtifacts(root);
            testCase.verifyEqual(repeated.removedCount, 0);
            testCase.verifyEmpty(repeated.removedTargets);
            testCase.verifyEmpty(repeated.errors);
            delete(cleanup);

            function recordProgress(message, value)
                progressMessages(end + 1, 1) = string(message);
                progressValues(end + 1, 1) = value;
            end
        end

        function rejectsUnsafeRoots(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            cleanup = addMaintenanceToolPath();
            testCase.addTeardown(@() delete(cleanup));

            testCase.verifyError(@() cleanLabKitArtifacts(root), ...
                "cleanLabKitArtifacts:InvalidRoot");
            testCase.verifyError(@() cleanLabKitArtifacts(" "), ...
                "cleanLabKitArtifacts:InvalidRoot");
            testCase.verifyError(@() cleanLabKitArtifacts(filesep), ...
                "cleanLabKitArtifacts:InvalidRoot");
        end

        function preservesTaskWorktreesWhileRemovingGeneratedSiblings(testCase)
            [root, cleanup] = temporaryLabKitRoot(testCase);
            testCase.addTeardown(@() delete(cleanup));
            taskRoot = fullfile(root, "artifacts", "worktrees", "sample-task");
            source = fullfile(taskRoot, "pending.m");
            marker = fullfile(taskRoot, ".git");
            writeFile(source, "pending = true;");
            writeFile(marker, "synthetic worktree marker");
            report = fullfile(root, "artifacts", "reports", "report.txt");
            log = fullfile(root, "artifacts", "run.log");
            writeFile(report, "generated");
            writeFile(log, "generated");

            result = cleanLabKitArtifacts(root);

            % Oracle: user-owned bytes survive while generated siblings vanish.
            % Deleting the artifacts parent would destroy both sentinels.
            testCase.assertTrue(isfile(source));
            testCase.verifyEqual(string(fileread(source)), "pending = true;");
            testCase.verifyEqual(string(fileread(marker)), "synthetic worktree marker");
            testCase.verifyFalse(isfile(report));
            testCase.verifyFalse(isfile(log));
            testCase.verifyEqual(sort(result.removedTargets), sort([ ...
                string(fullfile("artifacts", "reports")); ...
                string(fullfile("artifacts", "run.log"))]));
            testCase.verifyEqual(result.removedCount, 2);
            testCase.verifyEmpty(result.errors);
            repeated = cleanLabKitArtifacts(root);
            testCase.verifyEqual(repeated.removedCount, 0);
            testCase.verifyEmpty(repeated.errors);
            testCase.verifyTrue(isfile(source));
        end

        function preflightsGeneratedSiblingsBeforeAnyDeletion(testCase)
            [root, cleanup] = temporaryLabKitRoot(testCase);
            testCase.addTeardown(@() delete(cleanup));
            writeFile(fullfile(root, "artifacts", "worktrees", "pending.txt"), "pending");
            report = fullfile(root, "artifacts", "a-report.txt");
            writeFile(report, "generated");
            preserved = fullfile(root, "apps", "preserved");
            sentinel = fullfile(preserved, "sentinel.txt");
            writeFile(sentinel, "preserved");
            linkCleanup = createDirectoryLink( ...
                fullfile(root, "artifacts", "z-linked"), preserved);
            testCase.addTeardown(@() delete(linkCleanup));

            testCase.verifyError(@() cleanLabKitArtifacts(root), ...
                "cleanLabKitArtifacts:UnsafeTarget");
            testCase.verifyTrue(isfile(report));
            testCase.verifyTrue(isfile(sentinel));
        end

        function rejectsAnExistingTargetOutsideTheValidatedRoot(testCase)
            [root, cleanup] = temporaryLabKitRoot(testCase);
            testCase.addTeardown(@() delete(cleanup));
            outside = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            outsideFile = fullfile(outside, "preserved.txt");
            writeFile(outsideFile, "outside");
            linkCleanup = createDirectoryLink(fullfile(root, "artifacts"), outside);

            testCase.verifyError(@() cleanLabKitArtifacts(root), ...
                "cleanLabKitArtifacts:UnsafeTarget");
            testCase.verifyTrue(isfile(outsideFile));
            delete(linkCleanup);
        end

        function rejectsAnExistingTargetLinkedInsideTheValidatedRoot(testCase)
            [root, cleanup] = temporaryLabKitRoot(testCase);
            testCase.addTeardown(@() delete(cleanup));
            preserved = fullfile(root, "apps", "preserved");
            preservedFile = fullfile(preserved, "sentinel.txt");
            writeFile(preservedFile, "preserved");
            linkCleanup = createDirectoryLink(fullfile(root, "artifacts"), preserved);

            testCase.verifyError(@() cleanLabKitArtifacts(root), ...
                "cleanLabKitArtifacts:UnsafeTarget");
            testCase.verifyTrue(isfile(preservedFile));
            delete(linkCleanup);
        end
    end
end

function [root, cleanup] = temporaryLabKitRoot(testCase)
root = testCase.applyFixture( ...
    matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
writeFile(fullfile(root, "labkit_launcher.m"), "function labkit_launcher; end");
cleanup = addMaintenanceToolPath();
end

function cleanup = addMaintenanceToolPath()
toolFolder = fullfile(labkittest.setup(), "tools", "maintenance");
addpath(toolFolder, "-begin");
cleanup = onCleanup(@() rmpath(toolFolder));
end

function cleanup = createDirectoryLink(linkPath, targetPath)
if ispc
    command = sprintf('cmd /c mklink /J "%s" "%s"', linkPath, targetPath);
else
    command = sprintf('ln -s "%s" "%s"', targetPath, linkPath);
end
% Secondary-runtime test boundary: construct a filesystem link fixture.
[status, message] = system(command);
assert(status == 0, message);
cleanup = onCleanup(@() removeDirectoryLink(linkPath));
end

function removeDirectoryLink(linkPath)
delete(linkPath);
end

function writeFile(filepath, contents)
folder = fileparts(filepath);
if exist(folder, "dir") ~= 7
    mkdir(folder);
end
file = fopen(filepath, "w", "n", "UTF-8");
cleanup = onCleanup(@() fclose(file));
fprintf(file, "%s", contents);
clear cleanup
end
