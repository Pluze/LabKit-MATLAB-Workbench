classdef LauncherDispatchSpec < matlab.unittest.TestCase
    methods (Test, TestTags = {'Contract:system', 'Env:headless'})
        function publicCatalogHasExpectedMetadata(testCase)
            root = labkittest.setup();
            catalog = labkit.app.internal.launcher.dispatch(root, "list");

            testCase.verifyEqual(height(catalog), 21);
            testCase.verifyEqual(string(catalog.Properties.VariableNames), ...
                ["Family", "App", "Visibility", "Version", "Updated", "Command"]);
            testCase.verifyTrue(all(catalog.Visibility == "public"));
            testCase.verifyTrue(all(strlength(catalog.Version) > 0));
            testCase.verifyTrue(all(strlength(catalog.Updated) > 0));
        end

        function discoversPrivateRootsWithoutPrefixConfusion(testCase)
            root = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            external = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            writeEntry(root, fullfile("apps", "alpha"), "labkit_Public_app");
            writeEntry(root, fullfile("private_apps", "apps", "local"), "labkit_Local_app");
            writeEntry(external, fullfile("apps", "external"), "labkit_External_app");
            previous = getenv("LABKIT_PRIVATE_APP_ROOTS");
            cleanup = onCleanup(@() setenv("LABKIT_PRIVATE_APP_ROOTS", previous));
            setenv("LABKIT_PRIVATE_APP_ROOTS", external);

            catalog = labkit.app.internal.launcher.dispatch(root, "list");

            testCase.verifyEqual(string(catalog.Command), ...
                ["labkit_Public_app"; "labkit_External_app"; "labkit_Local_app"]);
            visibility = containers.Map(cellstr(catalog.Command), cellstr(catalog.Visibility));
            testCase.verifyEqual(string(visibility("labkit_Public_app")), "public");
            testCase.verifyEqual(string(visibility("labkit_Local_app")), "private");
            testCase.verifyEqual(string(visibility("labkit_External_app")), "private");
            clear cleanup
        end

        function sourceEntriesWinOverPcodeAndPcodeOnlyRemainsDiscoverable(testCase)
            root = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            folder = fullfile(root, "apps", "source", "probe");
            writeEntry(root, fullfile("apps", "source", "probe"), "labkit_Probe_app");
            fclose(fopen(fullfile(folder, "labkit_Probe_app.p"), "w"));
            pOnly = fullfile(root, "apps", "source", "p_only"); mkdir(pOnly);
            fclose(fopen(fullfile(pOnly, "labkit_Ponly_app.p"), "w"));
            catalog = labkit.app.internal.launcher.dispatch(root, "list");
            probe = catalog(catalog.Command == "labkit_Probe_app", :);
            testCase.verifyEqual(height(probe), 1);
            testCase.verifyEqual(string(probe.Version), "1.0.0");
            testCase.verifyEqual(sum(catalog.Command == "labkit_Ponly_app"), 1);
        end

        function documentationMapsManualToGeneratedPage(testCase)
            root = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            writeEntry(root, fullfile("apps", "image_tools", "marker"), "labkit_Marker_app");
            manual = fullfile(root, "docs", "apps", "image_tools", "marker", "README.md");
            generated = fullfile(root, "site", "apps", "image_tools", "marker.html");
            writeText(manual, "# Marker");
            writeText(generated, "<html></html>");

            page = labkit.app.internal.launcher.dispatch(root, "documentation", "labkit_Marker_app");

            testCase.verifyEqual(string(page), string(generated));
        end

        function documentationRejectsPrivateMissingAndUnbuiltPages(testCase)
            root = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            writeEntry(root, fullfile("apps", "image_tools", "marker"), "labkit_Marker_app");
            writeEntry(root, fullfile("private_apps", "apps", "private", "secret"), "labkit_Secret_app");
            writeText(fullfile(root, "docs", "apps", "image_tools", "marker", "README.md"), "# Marker");

            testCase.verifyError(@() labkit.app.internal.launcher.dispatch(root, "documentation", "labkit_Secret_app"), ...
                "labkit:app:internal:launcher:DocumentationUnavailable");
            testCase.verifyError(@() labkit.app.internal.launcher.dispatch(root, "documentation", "labkit_Marker_app"), ...
                "labkit:app:internal:launcher:DocumentationUnavailable");
            testCase.verifyError(@() labkit.app.internal.launcher.dispatch(root, "documentation", "labkit_Missing_app"), ...
                "labkit:app:internal:launcher:DocumentationUnavailable");
        end

        function structuralStartupOffersRepairButOrdinaryErrorsDoNot(testCase)
            cases = {"MATLAB:UndefinedFunction", true, "labkit_StructuralProbe_app"; "MATLAB:load:couldNotReadFile", false, "labkit_LoadProbe_app"; "fixture:InvalidInput", false, "labkit_InputProbe_app"};
            for index = 1:size(cases, 1)
                [root, cleanup] = hiddenLauncherFixture(testCase, cases{index, 1}, cases{index, 3});
                fig = labkit.app.internal.launcher.dispatch(root);
                button = findall(fig, "Type", "uibutton", "Text", "Open Selected App");
                button.ButtonPushedFcn(button, []);
                status = findall(fig, "Type", "uitextarea");
                text = string(status.Value);
                testCase.verifyTrue(any(contains(text, cases{index, 1})));
                testCase.verifyEqual(any(contains(text, "Repair / Reinstall")), cases{index, 2});
                delete(fig); delete(cleanup)
            end
        end

        function figureStudioHookForwardsTheExactAxesSentinel(testCase)
            root = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            folder = fullfile(root, "apps", "labkit_core", "figure_studio");
            mkdir(folder);
            writeText(fullfile(folder, "labkit_FigureStudio_app.m"), ...
                "function labkit_FigureStudio_app(mode, ax); setappdata(groot,'fixtureFigureStudioArgs',struct('mode',mode,'axes',ax)); end");
            previousPath = path;
            existing = which("labkit_FigureStudio_app");
            if strlength(string(existing)) > 0, rmpath(fileparts(existing)); end
            clear labkit_FigureStudio_app
            if isappdata(groot, "fixtureFigureStudioArgs"), rmappdata(groot, "fixtureFigureStudioArgs"); end
            hadHook = isappdata(groot, "labkitFigureStudioLauncher");
            priorHook = [];
            hadMode = isappdata(groot, "labkitLauncherGuiTestMode"); priorMode = [];
            hadPayload = isappdata(groot, "fixtureFigureStudioArgs"); priorPayload = [];
            if hadHook, priorHook = getappdata(groot, "labkitFigureStudioLauncher"); end
            if hadMode, priorMode = getappdata(groot, "labkitLauncherGuiTestMode"); end
            if hadPayload, priorPayload = getappdata(groot, "fixtureFigureStudioArgs"); end
            setappdata(groot, "labkitLauncherGuiTestMode", "hidden");
            cleanup = onCleanup(@() restoreFigureStudioFixture(previousPath, hadHook, priorHook, hadMode, priorMode, hadPayload, priorPayload));
            fig = labkit.app.internal.launcher.dispatch(root);
            sentinel = axes(figure("Visible", "off"));
            hook = getappdata(groot, "labkitFigureStudioLauncher");
            hook(sentinel);
            args = getappdata(groot, "fixtureFigureStudioArgs");
            testCase.verifyEqual(string(args.mode), "axes");
            testCase.verifyEqual(args.axes, sentinel);
            delete(ancestor(sentinel, "figure")); delete(fig); delete(cleanup)
        end

        function toolButtonsAdaptExactPublicContracts(testCase)
            root = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            command = "labkit_ToolProbe_app";
            writeEntry(root, fullfile("apps", "tools", "probe"), command);
            tools = {"maintenance", "cleanLabKitArtifacts"; "docs", "renderLabKitDocs"; "codecheck", "runCodecheckReport"; "profiling", "profileLabKitTarget"; "deployment", "packageLabKitApp"};
            for index = 1:size(tools, 1), writeToolStub(root, tools{index, 1}, tools{index, 2}); end
            dottedMaintenance = fullfile(root, "tools", "maintenance", ".");
            addpath(dottedMaintenance, "-begin");
            previousPath = path; hadMode = isappdata(groot, "labkitLauncherGuiTestMode"); priorMode = [];
            hadHook = isappdata(groot, "labkitFigureStudioLauncher"); priorHook = [];
            hadCall = isappdata(groot, "fixtureToolCall"); priorCall = [];
            if hadMode, priorMode = getappdata(groot, "labkitLauncherGuiTestMode"); end
            if hadHook, priorHook = getappdata(groot, "labkitFigureStudioLauncher"); end
            if hadCall, priorCall = getappdata(groot, "fixtureToolCall"); end
            setappdata(groot, "labkitLauncherGuiTestMode", "hidden");
            cleanup = onCleanup(@() restoreToolFixture(previousPath, hadMode, priorMode, hadHook, priorHook, hadCall, priorCall));
            fig = labkit.app.internal.launcher.dispatch(root);
            buttons = ["Clean Artifacts", "Build Documentation", "Code Analyzer", "Profile Selected App", "Package Selected App"];
            expected = ["cleanLabKitArtifacts", "renderLabKitDocs", "runCodecheckReport", "profileLabKitTarget", "packageLabKitApp"];
            for index = 1:numel(buttons)
                clear cleanLabKitArtifacts renderLabKitDocs runCodecheckReport profileLabKitTarget packageLabKitApp
                if isappdata(groot, "fixtureToolCall"), rmappdata(groot, "fixtureToolCall"); end
                button = findall(fig, "Type", "uibutton", "Text", buttons(index));
                button.ButtonPushedFcn(button, []);
                call = getappdata(groot, "fixtureToolCall");
                testCase.verifyEqual(string(call.name), expected(index));
                actual = call.args;
                switch index
                    case 1
                        expectedArgs = {root}; toolFolder = fullfile(root, "tools", "maintenance");
                    case 2
                        expectedArgs = {fullfile(root, "docs"), fullfile(root, "site")}; toolFolder = fullfile(root, "tools", "docs");
                    case 3
                        expectedArgs = {root}; toolFolder = fullfile(root, "tools", "codecheck");
                    case 4
                        expectedArgs = {char(command), [], "OpenReport", false, "WaitForGuiClose", false}; toolFolder = fullfile(root, "tools", "profiling");
                    otherwise
                        expectedArgs = {char(command), [], "Root", root, "CodeFormat", "source"}; toolFolder = fullfile(root, "tools", "deployment");
                end
                testCase.verifyEqual(numel(actual), numel(expectedArgs));
                for argumentIndex = 1:numel(expectedArgs)
                    testCase.verifyEqual(string(actual{argumentIndex}), string(expectedArgs{argumentIndex}));
                end
                if index == 1
                    testCase.verifyEqual(sum(normalizedPathEntries() == normalizePath(toolFolder)), 1);
                else
                    testCase.verifyFalse(any(strcmp(strsplit(path, pathsep), toolFolder)));
                end
                testCase.verifyFalse(contains(string(findall(fig, "Type", "uitextarea").Value), "failed", "IgnoreCase", true));
            end
            delete(fig); delete(cleanup)
        end
    end
end

function writeEntry(root, relativeFolder, command)
folder = fullfile(root, relativeFolder);
mkdir(folder);
writeText(fullfile(folder, command + ".m"), "function " + command + "; end");
[~, appId] = fileparts(folder);
definitionFolder = fullfile(folder, "+" + appId);
mkdir(definitionFolder);
writeText(fullfile(definitionFolder, "definition.m"), ...
    "function value = definition; value = struct(""AppVersion"", ""1.0.0"", ""Updated"", ""2026-01-01""); end");
end

function writeText(filepath, contents)
folder = fileparts(filepath);
if exist(folder, "dir") ~= 7
    mkdir(folder);
end
file = fopen(filepath, "w", "n", "UTF-8");
cleanup = onCleanup(@() fclose(file));
fprintf(file, "%s", contents);
delete(cleanup)
end

function restoreFigureStudioFixture(previousPath, hadHook, priorHook, hadMode, priorMode, hadPayload, priorPayload)
path(previousPath);
clear labkit_FigureStudio_app
if hadPayload, setappdata(groot, "fixtureFigureStudioArgs", priorPayload); elseif isappdata(groot, "fixtureFigureStudioArgs"), rmappdata(groot, "fixtureFigureStudioArgs"); end
if hadHook, setappdata(groot, "labkitFigureStudioLauncher", priorHook); elseif isappdata(groot, "labkitFigureStudioLauncher"), rmappdata(groot, "labkitFigureStudioLauncher"); end
if hadMode, setappdata(groot, "labkitLauncherGuiTestMode", priorMode); elseif isappdata(groot, "labkitLauncherGuiTestMode"), rmappdata(groot, "labkitLauncherGuiTestMode"); end
end

function writeToolStub(root, area, name)
folder = fullfile(root, "tools", area); mkdir(folder);
writeText(fullfile(folder, name + ".m"), ...
    "function " + name + "(varargin); setappdata(groot,'fixtureToolCall',struct('name',mfilename,'args',{varargin})); end");
end

function restoreToolFixture(previousPath, hadMode, priorMode, hadHook, priorHook, hadCall, priorCall)
path(previousPath);
clear cleanLabKitArtifacts renderLabKitDocs runCodecheckReport profileLabKitTarget packageLabKitApp
if hadCall, setappdata(groot, "fixtureToolCall", priorCall); elseif isappdata(groot, "fixtureToolCall"), rmappdata(groot, "fixtureToolCall"); end
if hadMode, setappdata(groot, "labkitLauncherGuiTestMode", priorMode); elseif isappdata(groot, "labkitLauncherGuiTestMode"), rmappdata(groot, "labkitLauncherGuiTestMode"); end
if hadHook, setappdata(groot, "labkitFigureStudioLauncher", priorHook); elseif isappdata(groot, "labkitFigureStudioLauncher"), rmappdata(groot, "labkitFigureStudioLauncher"); end
end

function entries = normalizedPathEntries()
entries = string(strsplit(path, pathsep));
for index = 1:numel(entries), entries(index) = normalizePath(entries(index)); end
end

function value = normalizePath(value)
pathValue = java.nio.file.Paths.get(char(value), javaArray("java.lang.String", 0));
value = string(pathValue.toAbsolutePath().normalize().toString());
if ispc, value = lower(value); end
end

function [root, cleanup] = hiddenLauncherFixture(testCase, identifier, command)
root = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
folder = fullfile(root, "apps", "fixture", "probe");
mkdir(folder); mkdir(fullfile(folder, "+probe"));
writeText(fullfile(folder, command + ".m"), ...
    "function " + command + "; error('" + identifier + "','" + identifier + "'); end");
writeText(fullfile(folder, "+probe", "definition.m"), ...
    "function value = definition; value = struct(""AppVersion"", ""1.0.0"", ""Updated"", ""2026-01-01""); end");
previousPath = path; hadMode = isappdata(groot, "labkitLauncherGuiTestMode"); priorMode = [];
hadHook = isappdata(groot, "labkitFigureStudioLauncher"); priorHook = [];
if hadMode, priorMode = getappdata(groot, "labkitLauncherGuiTestMode"); end
if hadHook, priorHook = getappdata(groot, "labkitFigureStudioLauncher"); end
setappdata(groot, "labkitLauncherGuiTestMode", "hidden");
cleanup = onCleanup(@() restoreHiddenLauncherFixture(previousPath, command, hadMode, priorMode, hadHook, priorHook));
end

function restoreHiddenLauncherFixture(previousPath, command, hadMode, priorMode, hadHook, priorHook)
path(previousPath); clear(command)
if hadMode, setappdata(groot, "labkitLauncherGuiTestMode", priorMode); elseif isappdata(groot, "labkitLauncherGuiTestMode"), rmappdata(groot, "labkitLauncherGuiTestMode"); end
if hadHook, setappdata(groot, "labkitFigureStudioLauncher", priorHook); elseif isappdata(groot, "labkitFigureStudioLauncher"), rmappdata(groot, "labkitFigureStudioLauncher"); end
end
