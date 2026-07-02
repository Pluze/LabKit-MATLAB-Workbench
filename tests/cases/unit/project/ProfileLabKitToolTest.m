classdef ProfileLabKitToolTest < matlab.unittest.TestCase
    %PROFILELABKITTOOLTEST Verify maintainer profiling tools.

    methods (Test, TestTags = {'Unit'})
        function profile_target_exports_html_and_agent_json_from_profile_info(testCase)
            root = setupLabKitTestPath();
            addToolsPathForTest(testCase, root);
            outputRoot = createTempFolder(testCase);
            profileInfo = syntheticProfileInfo(root);

            htmlFile = fullfile(outputRoot, "synthetic_profile.html");
            [actualHtml, artifacts] = profileLabKitTarget(profileInfo, htmlFile, ...
                "OpenReport", false, ...
                "SummaryTopN", 2);

            testCase.verifyEqual(string(actualHtml), string(htmlFile));
            testCase.verifyTrue(isfile(actualHtml));
            testCase.verifyTrue(isfile(artifacts.jsonFile));

            htmlText = string(fileread(actualHtml));
            artifactJson = jsondecode(fileread(artifacts.jsonFile));
            summaryText = string(artifactJson.summaryText);

            testCase.verifyTrue(contains(htmlText, "AGENT_SUMMARY_BEGIN"));
            testCase.verifyTrue(contains(htmlText, "agent-summary-json"));
            testCase.verifyTrue(contains(htmlText, "profile-json"));
            testCase.verifyTrue(contains(summaryText, "top_project_self_time:"));
            testCase.verifyTrue(contains(summaryText, "top_captured_self_time:"));
            testCase.verifyTrue(contains(summaryText, ...
                "labkit_launcher>initializeLauncherPath"));
            functionNames = string({artifactJson.functions.FunctionName});
            testCase.verifyTrue(any(functionNames == "path"), ...
                "The JSON sidecar should retain all captured profiler rows.");
            sourceTags = string({artifactJson.functions.SourceTag});
            testCase.verifyTrue(any(sourceTags == "project"));
            testCase.verifyTrue(any(sourceTags == "matlab_internal"));
            testCase.verifyTrue(isfield(artifactJson.summary, "topProjectSelfTime"));
            testCase.verifyTrue(isfield(artifactJson.summary, "topCapturedSelfTime"));
            testCase.verifyEqual(string(artifactJson.metadata.Target), ...
                "provided profile info structure");
            testCase.verifyEqual(artifactJson.metadata.ProjectFunctions, 2);
            testCase.verifyEqual(artifactJson.metadata.MatlabInternalFunctions, 1);
        end

        function profile_target_supports_batch_friendly_options(testCase)
            root = setupLabKitTestPath();
            addToolsPathForTest(testCase, root);
            outputRoot = createTempFolder(testCase);
            htmlFile = fullfile(outputRoot, "cli_profile.html");

            [~, result] = profileLabKitTarget("pause(0.001)", htmlFile, ...
                "OpenReport", false, ...
                "WaitForGuiClose", false, ...
                "CloseFiguresAfterRun", true, ...
                "OutputRoot", outputRoot, ...
                "PrintSummary", true, ...
                "SummaryTopN", 1);

            testCase.verifyTrue(isfile(result.htmlFile));
            testCase.verifyTrue(isfile(result.jsonFile));
            artifactJson = jsondecode(fileread(result.jsonFile));
            summaryText = string(artifactJson.summaryText);
            testCase.verifyTrue(contains(summaryText, "AGENT_SUMMARY_BEGIN"));
            testCase.verifyTrue(contains(summaryText, "AGENT_SUMMARY_END"));
        end
    end
end

function addToolsPathForTest(testCase, root)
    toolsPath = fullfile(root, "tools", "profiling");
    addpath(toolsPath);
    testCase.addTeardown(@() removePathIfPresent(toolsPath));
end

function folder = createTempFolder(testCase)
    folder = string(tempname);
    mkdir(folder);
    testCase.addTeardown(@() removeFolderIfPresent(folder));
end

function info = syntheticProfileInfo(root)
    ft = repmat(emptyProfileFunction(), 1, 3);
    ft(1) = profileFunction( ...
        "labkit_launcher", ...
        fullfile(root, "labkit_launcher.m"), ...
        1, 2.2, 0.1, emptyEdges(), [edge(2, 1, 1.2), edge(3, 3, 0.8)], [1 1 0.1]);
    ft(2) = profileFunction( ...
        "labkit_launcher>initializeLauncherPath", ...
        fullfile(root, "labkit_launcher.m"), ...
        1, 1.2, 1.2, edge(1, 1, 1.2), emptyEdges(), [95 1 1.2]);
    ft(3) = profileFunction( ...
        "path", ...
        fullfile(matlabroot, "toolbox", "matlab", "general", "path.m"), ...
        3, 0.8, 0.8, edge(1, 3, 0.8), emptyEdges(), [10 3 0.8]);
    info = struct("FunctionTable", ft, "ClockPrecision", 1e-6);
end

function f = emptyProfileFunction()
    f = struct();
    f.FunctionName = "";
    f.CompleteName = "";
    f.Type = "M-function";
    f.FileName = "";
    f.NumCalls = 0;
    f.TotalTime = 0;
    f.SelfTime = 0;
    f.Parents = emptyEdges();
    f.Children = emptyEdges();
    f.ExecutedLines = [];
end

function f = profileFunction(name, fileName, calls, totalTime, selfTime, parents, children, lines)
    f = emptyProfileFunction();
    f.FunctionName = char(name);
    f.CompleteName = char(name);
    f.FileName = char(fileName);
    f.NumCalls = calls;
    f.TotalTime = totalTime;
    f.SelfTime = selfTime;
    f.Parents = parents;
    f.Children = children;
    f.ExecutedLines = lines;
end

function value = edge(index, calls, totalTime)
    value = struct("Index", index, "NumCalls", calls, "TotalTime", totalTime);
end

function value = emptyEdges()
    value = struct("Index", {}, "NumCalls", {}, "TotalTime", {});
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
