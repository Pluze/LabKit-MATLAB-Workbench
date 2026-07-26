classdef LauncherDispatchSpec < matlab.unittest.TestCase
    methods (Test, TestTags = {'Contract:system', 'Env:headless'})
        function publicCatalogHasExpectedMetadata(testCase)
            root = labkittest.setup();
            catalog = labkit.app.internal.launcher.dispatch(root, "list");
            expectedPublic = publicEntryCommands(root);
            publicCatalog = catalog(catalog.Visibility == "public", :);

            testCase.verifyEqual(string(catalog.Properties.VariableNames), ...
                ["Command", "DisplayName", "Family", "Visibility", "Folder", ...
                "RelativePath", "Description", "Version", "Updated"]);
            testCase.verifyEqual(sort(publicCatalog.Command), sort(expectedPublic));
            testCase.verifyTrue(all(strlength(publicCatalog.DisplayName) > 0));
            testCase.verifyTrue(all(strlength(publicCatalog.Folder) > 0));
            testCase.verifyTrue(all(strlength(publicCatalog.Description) > 0));
            testCase.verifyTrue(all(strlength(publicCatalog.Version) > 0));
            testCase.verifyTrue(all(strlength(publicCatalog.Updated) > 0));
            privateCatalog = catalog(catalog.Visibility == "private", :);
            if ~isempty(privateCatalog)
                testCase.verifyTrue(all(strlength(privateCatalog.Command) > 0));
                testCase.verifyTrue(all(strlength(privateCatalog.DisplayName) > 0));
            end
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

        function launcherPreservesVisualSelectionAndDoubleClickContracts(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            commands = ["labkit_Alpha_app", "labkit_Beta_app"];
            writeEntry(root, fullfile("apps", "fixture", "alpha"), commands(1));
            writeEntry(root, fullfile("apps", "fixture", "beta"), commands(2));
            for command = commands
                filepath = fullfile(root, "apps", "fixture", ...
                    erase(erase(lower(command), "labkit_"), "_app"), command + ".m");
                writeText(filepath, "function " + command + ...
                    "; setappdata(groot,'fixtureLaunchedCommand',mfilename); end");
            end
            cleanup = launcherGuiFixture(commands);

            fig = labkit.app.internal.launcher.dispatch(root);
            appTable = findall(fig, "Type", "uitable");
            buttons = string({findall(fig, "Type", "uibutton").Text});
            panels = string({findall(fig, "Type", "uipanel").Title});

            screen = double(get(groot, "ScreenSize"));
            testCase.verifyLessThanOrEqual(fig.Position(3), screen(3));
            testCase.verifyLessThanOrEqual(fig.Position(4), screen(4));
            if screen(3) >= 1360
                testCase.verifyEqual(fig.Position(3), 1280);
            else
                testCase.verifyGreaterThanOrEqual( ...
                    fig.Position(3), max(1, screen(3) - 100));
            end
            if screen(4) >= 840
                testCase.verifyEqual(fig.Position(4), 720);
            else
                testCase.verifyGreaterThanOrEqual( ...
                    fig.Position(4), max(1, screen(4) - 140));
            end
            testCase.verifyEqual(fig.Color, [0.97 0.98 0.99]);
            testCase.verifyTrue(all(ismember([ ...
                "Launcher", "Applications", "Run Apps", ...
                "Versions and Install", "Development and Maintenance", ...
                "Package and Publish"], panels)));
            testCase.verifyEqual(string(appTable.ColumnName), [ ...
                "Package"; "App"; "Family"; "Version"; "Access"; "Updated"]);
            testCase.verifyEqual(appTable.ColumnEditable, ...
                [true false false false false false]);
            testCase.verifyEqual(appTable.FontSize, 12);
            testCase.verifyTrue(all(cellfun( ...
                @(value) isnumeric(value) && isscalar(value), ...
                appTable.ColumnWidth)));
            initialWidths = cell2mat(appTable.ColumnWidth);
            testCase.verifyGreaterThan(initialWidths(2), initialWidths(1));
            fig.Position(3) = max(800, fig.Position(3) - 160);
            fig.SizeChangedFcn(fig, []);
            drawnow;
            resizedWidths = cell2mat(appTable.ColumnWidth);
            testCase.verifyLessThanOrEqual( ...
                sum(resizedWidths), sum(initialWidths));
            testCase.verifyGreaterThanOrEqual(resizedWidths, ...
                [62 180 120 70 72 90]);
            testCase.verifyTrue(all(ismember([ ...
                "Open Selected App", "Refresh App List", ...
                "Documentation and History", "Latest", "Release", "Versions", ...
                "Update Documentation", "Run Code Analyzer", ...
                "Profile Selected App", "Clean Artifacts", ...
                "Package Checked", "Checked P-code"], buttons)));
            testCase.verifyFalse(any(buttons == "Open Debug"));

            invokeTableSelection(appTable, 2);
            testCase.verifyTrue(any(contains(launcherText(fig), commands(2))));
            invokeTableDoubleClick(appTable, 2);
            testCase.verifyEqual(string(getappdata( ...
                groot, "fixtureLaunchedCommand")), commands(2));
            testCase.verifyTrue(any(contains(launcherText(fig), ...
                "Opened " + commands(2))));
            view = getappdata(fig, "labkitLauncherView");
            testCase.verifyEqual(view.controls.appTable.table, appTable);
            delete(fig); delete(cleanup)
        end

        function versionButtonsUseTheIndependentVersionTool(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            writeEntry(root, fullfile("apps", "fixture", "probe"), ...
                "labkit_Probe_app");
            writeVersionToolStub(root);
            cleanup = launcherGuiFixture("manageLabKitVersions");

            fig = labkit.app.internal.launcher.dispatch(root);
            for buttonText = ["Latest", "Release", "Versions"]
                button = findall(fig, "Type", "uibutton", "Text", buttonText);
                button.ButtonPushedFcn(button, []);
            end

            calls = getappdata(groot, "fixtureVersionCalls");
            testCase.verifyNumElements(calls, 3);
            testCase.verifyEqual(string(cellfun( ...
                @(call) call{2}, calls, "UniformOutput", false)), ...
                ["main", "stable", "browse"]);
            for index = 1:numel(calls)
                testCase.verifyEqual(string(calls{index}{1}), string(root));
                testCase.verifyEqual(string(calls{index}{3}), "ProgressFcn");
                testCase.verifyClass(calls{index}{4}, "function_handle");
            end
            testCase.verifyTrue(any(contains(launcherText(fig), ...
                "Opened LabKit Version Manager.")));
            delete(fig); delete(cleanup)
        end

        function packageCheckboxesDriveMultiAppSourceAndPcodeCalls(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            commands = ["labkit_Alpha_app", "labkit_Beta_app"];
            writeEntry(root, fullfile("apps", "fixture", "alpha"), commands(1));
            writeEntry(root, fullfile("apps", "fixture", "beta"), commands(2));
            writeToolStub(root, "deployment", "packageLabKitApp");
            cleanup = launcherGuiFixture("packageLabKitApp");

            fig = labkit.app.internal.launcher.dispatch(root);
            appTable = findall(fig, "Type", "uitable");
            invokePackageEdit(appTable, 1, true);
            invokePackageEdit(appTable, 2, true);
            for buttonText = ["Package Checked", "Checked P-code"]
                button = findall(fig, "Type", "uibutton", "Text", buttonText);
                button.ButtonPushedFcn(button, []);
            end

            calls = getappdata(groot, "fixtureToolCalls");
            testCase.verifyNumElements(calls, 2);
            for index = 1:2
                args = calls{index}.args;
                testCase.verifyEqual(sort(string(args{1})), sort(commands));
                testCase.verifyEmpty(args{2});
                expectedFormat = ["source", "pcode"];
                testCase.verifyEqual(string(args{3}), "Root");
                testCase.verifyEqual(string(args{4}), string(root));
                testCase.verifyEqual(string(args{5}), "CodeFormat");
                testCase.verifyEqual(string(args{6}), expectedFormat(index));
                testCase.verifyEqual(string(args{7}), "ProgressFcn");
                testCase.verifyClass(args{8}, "function_handle");
            end
            delete(fig); delete(cleanup)
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
                testCase.verifyEqual(any(contains(text, ...
                    "labkit_launcher(""repair"")")), cases{index, 2});
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
            tools = {
                "maintenance", "cleanLabKitArtifacts"
                "docs", "renderLabKitDocs"
                "codecheck", "runCodecheckReport"
                "profiling", "profileLabKitTarget"
                };
            for index = 1:size(tools, 1)
                writeToolStub(root, tools{index, 1}, tools{index, 2});
            end
            cleanup = launcherGuiFixture(string(tools(:, 2)));
            dottedMaintenance = fullfile(root, "tools", "maintenance", ".");
            addpath(dottedMaintenance, "-begin");
            fig = labkit.app.internal.launcher.dispatch(root);
            buttons = [ ...
                "Clean Artifacts", "Update Documentation", ...
                "Run Code Analyzer", "Profile Selected App"];
            expected = [ ...
                "cleanLabKitArtifacts", "renderLabKitDocs", ...
                "runCodecheckReport", "profileLabKitTarget"];
            for index = 1:numel(buttons)
                clear cleanLabKitArtifacts renderLabKitDocs ...
                    runCodecheckReport profileLabKitTarget
                if isappdata(groot, "fixtureToolCall")
                    rmappdata(groot, "fixtureToolCall");
                end
                button = findall(fig, "Type", "uibutton", "Text", buttons(index));
                button.ButtonPushedFcn(button, []);
                call = getappdata(groot, "fixtureToolCall");
                testCase.verifyEqual(string(call.name), expected(index));
                actual = call.args;
                switch index
                    case 1
                        testCase.verifyEqual(string(actual{1}), string(root));
                        testCase.verifyEqual(string(actual{2}), "ProgressFcn");
                        testCase.verifyClass(actual{3}, "function_handle");
                        toolFolder = fullfile(root, "tools", "maintenance");
                    case 2
                        testCase.verifyEqual(string(actual), string({ ...
                            fullfile(root, "docs"), fullfile(root, "site")}));
                        toolFolder = fullfile(root, "tools", "docs");
                    case 3
                        testCase.verifyEqual(string(actual{1}), string(root));
                        testCase.verifyEqual(string(actual{2}), "ProgressFcn");
                        testCase.verifyClass(actual{3}, "function_handle");
                        toolFolder = fullfile(root, "tools", "codecheck");
                    otherwise
                        testCase.verifyEqual(string(actual{1}), command);
                        testCase.verifyEmpty(actual{2});
                        testCase.verifyEqual(string(actual{3}), "OpenReport");
                        testCase.verifyFalse(actual{4});
                        testCase.verifyEqual(string(actual{5}), "WaitForGuiClose");
                        testCase.verifyFalse(actual{6});
                        toolFolder = fullfile(root, "tools", "profiling");
                end
                if index == 1
                    testCase.verifyEqual(sum(normalizedPathEntries() == normalizePath(toolFolder)), 1);
                else
                    testCase.verifyFalse(any(strcmp(strsplit(path, pathsep), toolFolder)));
                end
                testCase.verifyFalse(any(contains(launcherText(fig), ...
                    "failed", "IgnoreCase", true)));
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
contents = [
    "function varargout = " + name + "(varargin)"
    "call = struct(""name"", string(mfilename), ""args"", {varargin});"
    "setappdata(groot, ""fixtureToolCall"", call);"
    "calls = {};"
    "if isappdata(groot, ""fixtureToolCalls"")"
    "    calls = getappdata(groot, ""fixtureToolCalls"");"
    "end"
    "calls{end + 1} = call;"
    "setappdata(groot, ""fixtureToolCalls"", calls);"
    "if nargout > 0"
    "    switch string(mfilename)"
    "        case ""cleanLabKitArtifacts"""
    "            result = struct(""removedCount"", 0);"
    "        case ""packageLabKitApp"""
    "            result = struct(""zipFile"", ""synthetic-package.zip"");"
    "        otherwise"
    "            result = struct();"
    "    end"
    "    varargout = cell(1, nargout);"
    "    varargout{1} = result;"
    "end"
    "end"
    ];
writeText(fullfile(folder, name + ".m"), strjoin(contents, newline));
end

function writeVersionToolStub(root)
folder = fullfile(root, "tools", "deployment");
mkdir(folder);
contents = [
    "function result = manageLabKitVersions(varargin)"
    "calls = {};"
    "if isappdata(groot, ""fixtureVersionCalls"")"
    "    calls = getappdata(groot, ""fixtureVersionCalls"");"
    "end"
    "calls{end + 1} = varargin;"
    "setappdata(groot, ""fixtureVersionCalls"", calls);"
    "result = struct(""message"", ""Version action complete."");"
    "end"
    ];
writeText(fullfile(folder, "manageLabKitVersions.m"), ...
    strjoin(contents, newline));
end

function commands = publicEntryCommands(root)
sourceEntries = dir(fullfile(root, "apps", "**", "labkit_*_app.m"));
pcodeEntries = dir(fullfile(root, "apps", "**", "labkit_*_app.p"));
names = [string({sourceEntries.name}), string({pcodeEntries.name})];
commands = unique(erase(names, [".m", ".p"]), "stable").';
end

function cleanup = launcherGuiFixture(functionNames)
previousPath = path;
functionNames = string(functionNames(:));
keys = [
    "labkitLauncherGuiTestMode"
    "labkitFigureStudioLauncher"
    "fixtureLaunchedCommand"
    "fixtureVersionCalls"
    "fixtureToolCall"
    "fixtureToolCalls"
    ];
hadValues = false(size(keys));
priorValues = cell(size(keys));
for index = 1:numel(keys)
    hadValues(index) = isappdata(groot, keys(index));
    if hadValues(index)
        priorValues{index} = getappdata(groot, keys(index));
    end
end
setappdata(groot, "labkitLauncherGuiTestMode", "hidden");
clearNamedFunctions(functionNames);
cleanup = onCleanup(@() restoreLauncherGuiFixture( ...
    previousPath, functionNames, keys, hadValues, priorValues));
end

function restoreLauncherGuiFixture( ...
        previousPath, functionNames, keys, hadValues, priorValues)
path(previousPath);
clearNamedFunctions(functionNames);
for index = 1:numel(keys)
    if hadValues(index)
        setappdata(groot, keys(index), priorValues{index});
    elseif isappdata(groot, keys(index))
        rmappdata(groot, keys(index));
    end
end
end

function clearNamedFunctions(functionNames)
for name = functionNames.'
    clear(char(name));
end
end

function values = launcherText(fig)
textAreas = findall(fig, "Type", "uitextarea");
chunks = cell(numel(textAreas), 1);
for index = 1:numel(textAreas)
    chunks{index} = string(textAreas(index).Value(:));
end
if isempty(chunks)
    values = strings(0, 1);
else
    values = vertcat(chunks{:});
end
end

function invokeTableSelection(tableHandle, row)
if isprop(tableHandle, "SelectionChangedFcn") && ...
        ~isempty(tableHandle.SelectionChangedFcn)
    invokeCallback(tableHandle.SelectionChangedFcn, tableHandle, ...
        struct("Selection", [row 1]));
else
    invokeCallback(tableHandle.CellSelectionCallback, tableHandle, ...
        struct("Indices", [row 1]));
end
end

function invokeTableDoubleClick(tableHandle, row)
if isprop(tableHandle, "DoubleClickedFcn") && ...
        ~isempty(tableHandle.DoubleClickedFcn)
    callback = tableHandle.DoubleClickedFcn;
elseif isprop(tableHandle, "CellDoubleClickedFcn") && ...
        ~isempty(tableHandle.CellDoubleClickedFcn)
    callback = tableHandle.CellDoubleClickedFcn;
else
    error("fixture:MissingDoubleClickCallback", ...
        "The launcher app table has no double-click callback.");
end
invokeCallback(callback, tableHandle, struct( ...
    "Selection", [row 1], "Indices", [row 1]));
end

function invokePackageEdit(tableHandle, row, value)
tableHandle.Data{row, 1} = value;
invokeCallback(tableHandle.CellEditCallback, tableHandle, ...
    struct("Indices", [row 1], "NewData", value));
end

function invokeCallback(callback, source, event)
if isa(callback, "function_handle")
    callback(source, event);
else
    feval(callback{1}, source, event, callback{2:end});
end
end

function entries = normalizedPathEntries()
entries = string(strsplit(path, pathsep));
entries = entries(strlength(entries) > 0);
for index = 1:numel(entries)
    entries(index) = normalizePath(entries(index));
end
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
