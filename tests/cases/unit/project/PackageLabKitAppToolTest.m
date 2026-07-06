classdef PackageLabKitAppToolTest < matlab.unittest.TestCase
    %PACKAGELABKITAPPTOOLTEST Verify single-app deployment packaging.

    methods (Test, TestTags = {'Unit'})
        function package_contains_launcher_tools_library_and_one_public_app(testCase)
            sourceRoot = setupLabKitTestPath();
            addDeploymentToolPathForTest(testCase, sourceRoot);
            runtimeRoot = createMinimalRuntime(testCase, sourceRoot);
            outputRoot = createTempFolder(testCase);
            createMinimalApp(runtimeRoot, fullfile("apps", "public_family", "public_probe"), ...
                "labkit_PublicProbe_app");
            createMinimalApp(runtimeRoot, fullfile("apps", "other_family", "other_probe"), ...
                "labkit_OtherProbe_app");

            result = packageLabKitApp("labkit_PublicProbe_app", [], ...
                "Root", runtimeRoot, ...
                "OutputRoot", outputRoot);
            packageRoot = unzipPackage(testCase, result);

            testCase.verifyTrue(isfile(fullfile(packageRoot, "labkit_launcher.m")));
            testCase.verifyTrue(isfile(fullfile(packageRoot, "tools", "deployment", "packageLabKitApp.m")));
            testCase.verifyTrue(isfile(fullfile(packageRoot, "tools", "profiling", "profileLabKitTarget.m")));
            testCase.verifyTrue(isfile(fullfile(packageRoot, "+labkit", "+ui", "version.m")));
            testCase.verifyTrue(isfile(fullfile(packageRoot, "run_labkit_PublicProbe_app.m")));
            testCase.verifyTrue(isfile(fullfile(packageRoot, "apps", "public_family", ...
                "public_probe", "labkit_PublicProbe_app.m")));
            testCase.verifyTrue(isfile(fullfile(packageRoot, "apps", "public_family", ...
                "public_probe", "assets", "calibration.json")));
            testCase.verifyFalse(isfile(fullfile(packageRoot, "apps", "other_family", ...
                "other_probe", "labkit_OtherProbe_app.m")), ...
                "A single-app package should not include sibling apps.");

            manifest = jsondecode(fileread(fullfile(packageRoot, "packaged_app_manifest.json")));
            testCase.verifyEqual(string(manifest.appFolder), "apps/public_family/public_probe");
            testCase.verifyEqual(string(manifest.visibility), "public");
        end

        function package_preserves_private_app_folder_without_source_paths(testCase)
            sourceRoot = setupLabKitTestPath();
            addDeploymentToolPathForTest(testCase, sourceRoot);
            runtimeRoot = createMinimalRuntime(testCase, sourceRoot);
            privateWorkspace = createTempFolder(testCase);
            createMinimalApp(privateWorkspace, fullfile("apps", "private_family", "private_probe"), ...
                "labkit_PrivateProbe_app");
            outputRoot = createTempFolder(testCase);
            cleanupEnv = setPrivateRootsForTest(privateWorkspace);

            result = packageLabKitApp("labkit_PrivateProbe_app", [], ...
                "Root", runtimeRoot, ...
                "OutputRoot", outputRoot);
            packageRoot = unzipPackage(testCase, result);

            privateAppFile = fullfile(packageRoot, "private_apps", "apps", ...
                "private_family", "private_probe", "labkit_PrivateProbe_app.m");
            privateAsset = fullfile(packageRoot, "private_apps", "apps", ...
                "private_family", "private_probe", "assets", "calibration.json");
            testCase.verifyTrue(isfile(privateAppFile), ...
                "Private app packages should keep the private_apps/apps folder shape.");
            testCase.verifyTrue(isfile(privateAsset));
            testCase.verifyFalse(isfolder(fullfile(packageRoot, "apps", "private_family")), ...
                "Private app packages should not flatten private apps into public apps.");

            manifestText = string(fileread(fullfile(packageRoot, "packaged_app_manifest.json")));
            readmeText = string(fileread(fullfile(packageRoot, "README.txt")));
            testCase.verifyTrue(contains(manifestText, "private_apps/apps/private_family/private_probe"));
            testCase.verifyFalse(contains(manifestText, string(runtimeRoot)));
            testCase.verifyFalse(contains(manifestText, string(privateWorkspace)));
            testCase.verifyFalse(contains(readmeText, string(runtimeRoot)));
            testCase.verifyFalse(contains(readmeText, string(privateWorkspace)));

            clear cleanupEnv;
        end

        function package_can_encode_matlab_code_as_p_files(testCase)
            sourceRoot = setupLabKitTestPath();
            addDeploymentToolPathForTest(testCase, sourceRoot);
            runtimeRoot = createMinimalRuntime(testCase, sourceRoot);
            outputRoot = createTempFolder(testCase);
            createMinimalApp(runtimeRoot, fullfile("apps", "public_family", "pcode_probe"), ...
                "labkit_PcodeProbe_app");

            result = packageLabKitApp("labkit_PcodeProbe_app", [], ...
                "Root", runtimeRoot, ...
                "OutputRoot", outputRoot, ...
                "CodeFormat", "pcode");
            packageRoot = unzipPackage(testCase, result);

            testCase.verifyEqual(result.codeFormat, "pcode");
            testCase.verifyEqual(result.entryFile, "run_labkit_PcodeProbe_app.p");
            testCase.verifyTrue(isfile(fullfile(packageRoot, "labkit_launcher.p")));
            testCase.verifyTrue(isfile(fullfile(packageRoot, "run_labkit_PcodeProbe_app.p")));
            testCase.verifyTrue(isfile(fullfile(packageRoot, "apps", "public_family", ...
                "pcode_probe", "labkit_PcodeProbe_app.p")));
            testCase.verifyTrue(isfile(fullfile(packageRoot, "tools", "deployment", "packageLabKitApp.p")));
            testCase.verifyTrue(isfile(fullfile(packageRoot, "tools", "profiling", "profileLabKitTarget.p")));
            testCase.verifyFalse(isfile(fullfile(packageRoot, "labkit_launcher.m")));
            testCase.verifyFalse(isfile(fullfile(packageRoot, "run_labkit_PcodeProbe_app.m")));
            testCase.verifyFalse(isfile(fullfile(packageRoot, "apps", "public_family", ...
                "pcode_probe", "labkit_PcodeProbe_app.m")));
            testCase.verifyTrue(isfile(fullfile(packageRoot, "apps", "public_family", ...
                "pcode_probe", "assets", "calibration.json")));

            manifest = jsondecode(fileread(fullfile(packageRoot, "packaged_app_manifest.json")));
            testCase.verifyEqual(string(manifest.codeFormat), "pcode");
            testCase.verifyEqual(string(manifest.entryFile), "run_labkit_PcodeProbe_app.p");

            originalFolder = pwd;
            cd(packageRoot);
            testCase.addTeardown(@() cd(originalFolder));
            clear labkit_launcher;
            apps = labkit_launcher("list");
            testCase.verifyEqual(apps.Command, "labkit_PcodeProbe_app");
            testCase.verifyEqual(apps.Visibility, "public");
            clear labkit_launcher;
            cd(originalFolder);
        end
    end
end

function addDeploymentToolPathForTest(testCase, root)
    toolPath = fullfile(root, "tools", "deployment");
    addpath(toolPath);
    testCase.addTeardown(@() removePathIfPresent(toolPath));
end

function root = createMinimalRuntime(testCase, sourceRoot)
    root = createTempFolder(testCase);
    copyfile(fullfile(sourceRoot, "labkit_launcher.m"), fullfile(root, "labkit_launcher.m"));
    mkdir(fullfile(root, "+labkit", "+ui"));
    writeText(fullfile(root, "+labkit", "+ui", "version.m"), sprintf([ ...
        'function info = version()\n' ...
        'info = struct("version", "0.0.0");\n' ...
        'end\n']));
    mkdir(fullfile(root, "tools"));
    copyfile(fullfile(sourceRoot, "tools", "deployment"), fullfile(root, "tools", "deployment"));
    copyfile(fullfile(sourceRoot, "tools", "profiling"), fullfile(root, "tools", "profiling"));
end

function folder = createTempFolder(testCase)
    folder = string(tempname);
    mkdir(folder);
    testCase.addTeardown(@() removeFolderIfPresent(folder));
end

function appFolder = createMinimalApp(root, relativeFolder, command)
    appFolder = fullfile(root, relativeFolder);
    mkdir(appFolder);
    writeText(fullfile(appFolder, command + ".m"), sprintf([ ...
        'function varargout = %s(varargin)\n' ...
        '%%%s Minimal package test app.\n' ...
        'if nargout > 0\n' ...
        '    varargout = {[]};\n' ...
        'end\n' ...
        'end\n'], command, upper(command)));
    mkdir(fullfile(appFolder, "assets"));
    writeText(fullfile(appFolder, "assets", "calibration.json"), '{"device":"DEVICE"}');
end

function packageRoot = unzipPackage(testCase, result)
    outputRoot = createTempFolder(testCase);
    unzip(result.zipFile, outputRoot);
    packageRoot = fullfile(outputRoot, result.packageRootName);
    testCase.verifyTrue(isfolder(packageRoot), ...
        "Package zip should expand to the returned package root folder.");
end

function cleanup = setPrivateRootsForTest(folder)
    previous = getenv("LABKIT_PRIVATE_APP_ROOTS");
    setenv("LABKIT_PRIVATE_APP_ROOTS", char(folder));
    cleanup = onCleanup(@() setenv("LABKIT_PRIVATE_APP_ROOTS", previous));
end

function writeText(filepath, text)
    fid = fopen(filepath, "w");
    assert(fid > 0, "Could not write test file: %s", filepath);
    cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, "%s", text);
    clear cleanup;
end

function removeFolderIfPresent(folder)
    if exist(folder, "dir") == 7
        rmdir(folder, "s");
    end
end

function removePathIfPresent(folder)
    paths = string(strsplit(path, pathsep));
    if ispc
        match = strcmpi(paths, string(folder));
    else
        match = strcmp(paths, string(folder));
    end
    if any(match)
        rmpath(char(folder));
    end
end
