classdef AppSdkUsageGuardrailTest < matlab.unittest.TestCase
    %APPSDKUSAGEGUARDRAIL Guard Apps toward the public App SDK boundary.

    methods (Test, TestTags = {'Integration', 'Style'})
        function appsUseOnlyPublicAppSdkNames(testCase)
            setupLabKitTestPath();
            root = testRepoRoot();
            files = appSourceFiles(root);
            forbidden = [
                "labkit.app.internal."
                "labkitUiRegistry"
                "labkitUiAppRuntime"
            ];

            hits = strings(0, 1);
            for k = 1:numel(files)
                source = fileread(files(k));
                for n = 1:numel(forbidden)
                    if contains(source, forbidden(n))
                        hits(end+1, 1) = relativePath(root, files(k)) + ...
                            " uses " + forbidden(n);
                    end
                end
            end

            testCase.verifyEmpty(hits, ...
                "Apps should use only public App SDK contracts: " + ...
                strjoin(hits, "; "));
        end

        function appsDoNotReimplementPlotClear(testCase)
            setupLabKitTestPath();
            root = testRepoRoot();
            files = appSourceFiles(root);
            hits = strings(0, 1);
            for k = 1:numel(files)
                source = fileread(files(k));
                clearsGraphics = contains(source, "delete(allchild(") || ...
                    contains(source, "delete(ax.Children)") || ...
                    contains(source, "delete(axesHandle.Children)");
                resetsAxes = contains(source, "XLimMode = 'auto'") && ...
                    contains(source, "YLimMode = 'auto'");
                clearsLegend = contains(source, "legend(ax, 'off'") || ...
                    contains(source, "legend(axesHandle, 'off'");
                if clearsGraphics && resetsAxes && clearsLegend
                    hits(end+1, 1) = relativePath(root, files(k));
                end
            end

            testCase.verifyEmpty(hits, ...
                "Apps should call labkit.app.plot.clearAxes instead of reimplementing axes cleanup: " + ...
                strjoin(hits, ", "));
        end

        function appActionsOwnExplanatoryTooltips(testCase)
            root = setupLabKitTestPath();
            definitions = dir(fullfile(root, "apps", "**", "definition.m"));
            hits = strings(0, 1);
            for k = 1:numel(definitions)
                packageFolder = string(definitions(k).folder);
                [~, packageName] = fileparts(packageFolder);
                packageName = extractAfter(packageName, 1);
                definition = feval(packageName + ".definition");
                plan = labkit.app.internal.DefinitionInspector.platformPlan( ...
                    definition);
                for n = 1:numel(plan.Nodes)
                    node = plan.Nodes(n);
                    config = node.Configuration;
                    if node.Kind == "button" && ...
                            config.Tooltip == config.Label
                        hits(end + 1, 1) = packageName + ":" + node.Id + ...
                            " repeats its label";
                    elseif node.Kind == "fileList" && ...
                            config.ChooseTooltip == config.ChooseLabel
                        hits(end + 1, 1) = packageName + ":" + node.Id + ...
                            " repeats its choose label";
                    end
                end
            end

            testCase.verifyEmpty(hits, ...
                "App actions should explain their scientific or workflow " + ...
                "effect instead of repeating the visible label: " + ...
                strjoin(hits, "; "));
        end
    end
end

function files = appSourceFiles(root)
    scope = labkitQualityScanScope(root);
    files = scope.appMFiles;
end

function rel = relativePath(root, filepath)
    root = char(root);
    filepath = char(filepath);
    prefix = [root filesep];
    if startsWith(filepath, prefix)
        rel = string(filepath(numel(prefix)+1:end));
    else
        rel = string(filepath);
    end
end
