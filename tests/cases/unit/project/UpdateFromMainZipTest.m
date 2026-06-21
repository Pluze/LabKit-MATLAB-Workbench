classdef UpdateFromMainZipTest < matlab.unittest.TestCase
    %UPDATEFROMMAINZIPTEST Verify safe zip-based updater behavior.

    methods (Test, TestTags = {'Unit'})
        function updater_rejects_git_checkouts(testCase)
            root = setupLabKitTestPath();
            addpath(fullfile(root, "scripts"), "-end");
            testCase.addTeardown(@() rmpathIfPresent(fullfile(root, "scripts")));

            try
                updateLabKitFromMainZip( ...
                    "Root", root, ...
                    "SourceUrl", "unused.zip", ...
                    "Confirm", false);
                testCase.verifyFail("Git checkouts should reject zip updates.");
            catch err
                testCase.verifyEqual(string(err.identifier), ...
                    "updateLabKitFromMainZip:GitCheckout");
                testCase.verifyTrue(contains(string(err.message), ...
                    "disabled for git checkouts"));
                testCase.verifyFalse(contains(string(err.message), ...
                    "message identifier"));
            end
        end

        function updater_preserves_user_files_and_backs_up_managed_files(testCase)
            root = setupLabKitTestPath();
            addpath(fullfile(root, "scripts"), "-end");
            testCase.addTeardown(@() rmpathIfPresent(fullfile(root, "scripts")));

            workRoot = string(tempname);
            mkdir(workRoot);
            testCase.addTeardown(@() removeFolderIfPresent(workRoot));

            installRoot = fullfile(workRoot, "LabKit-install");
            sourceParent = fullfile(workRoot, "source");
            sourceRoot = fullfile(sourceParent, "LabKit-main");
            makeInstallRoot(installRoot, "old");
            makeInstallRoot(sourceRoot, "new");
            writeTextFile(fullfile(installRoot, "apps", "user_notes.txt"), ...
                "keep user app note" + newline);
            writeTextFile(fullfile(installRoot, "user_root_data.txt"), ...
                "keep root note" + newline);
            writeTextFile(fullfile(installRoot, "apps", "retiredProjectFile.m"), ...
                "% retired" + newline);
            writeTextFile(fullfile(installRoot, ".labkit-managed-files.txt"), ...
                strjoin(["README.md", "labkit_launcher.m", ...
                "apps/retiredProjectFile.m"], newline) + newline);

            zipPath = fullfile(workRoot, "main.zip");
            zip(char(zipPath), {'LabKit-main'}, char(sourceParent));

            result = updateLabKitFromMainZip( ...
                "Root", installRoot, ...
                "SourceUrl", zipPath, ...
                "Confirm", false, ...
                "TempRoot", fullfile(workRoot, "update-temp"));

            testCase.verifyTrue(contains(string(fileread(fullfile( ...
                installRoot, "README.md"))), "new"));
            testCase.verifyTrue(isfile(fullfile(installRoot, ...
                "apps", "user_notes.txt")));
            testCase.verifyTrue(isfile(fullfile(installRoot, ...
                "user_root_data.txt")));
            testCase.verifyFalse(isfile(fullfile(installRoot, ...
                "apps", "retiredProjectFile.m")));
            testCase.verifyTrue(isfile(result.backupZip));

            backupExtract = fullfile(workRoot, "backup");
            unzip(result.backupZip, backupExtract);
            testCase.verifyTrue(isfile(fullfile(backupExtract, "README.md")));
            testCase.verifyFalse(isfile(fullfile(backupExtract, ...
                "apps", "user_notes.txt")));
        end
    end
end

function makeInstallRoot(root, marker)
    mkdir(root);
    mkdir(fullfile(root, "+labkit"));
    mkdir(fullfile(root, "apps"));
    mkdir(fullfile(root, "scripts"));
    writeTextFile(fullfile(root, "labkit_launcher.m"), ...
        "function labkit_launcher" + newline + "end" + newline);
    writeTextFile(fullfile(root, "README.md"), marker + newline);
    writeTextFile(fullfile(root, "+labkit", "placeholder.m"), ...
        "function placeholder" + newline + "end" + newline);
    writeTextFile(fullfile(root, "apps", "managed_app.m"), ...
        "function managed_app" + newline + "end" + newline);
    writeTextFile(fullfile(root, "scripts", "updateLabKitFromMainZip.m"), ...
        "function updateLabKitFromMainZip" + newline + "end" + newline);
end

function writeTextFile(filepath, text)
    folder = fileparts(filepath);
    if exist(folder, "dir") ~= 7
        mkdir(folder);
    end
    fid = fopen(filepath, "w");
    assert(fid > 0, "Could not write test file: %s", filepath);
    cleaner = onCleanup(@() fclose(fid));
    fprintf(fid, "%s", text);
    clear cleaner;
end

function rmpathIfPresent(folder)
    paths = strsplit(path, pathsep);
    if any(strcmp(paths, folder))
        rmpath(folder);
    end
end

function removeFolderIfPresent(folder)
    if exist(folder, "dir") == 7
        rmdir(folder, "s");
    end
end
