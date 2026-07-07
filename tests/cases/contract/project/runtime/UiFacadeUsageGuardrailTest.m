classdef UiFacadeUsageGuardrailTest < matlab.unittest.TestCase
    %UIFACADEUSAGEGUARDRAIL Guard app code toward the UI5 facade split.

    methods (Test, TestTags = {'Integration', 'Style'})
        function test_apps_use_ui5_facade_names(testCase)
            setupLabKitTestPath();
            root = testRepoRoot();
            files = appSourceFiles(root);
            forbidden = [
                "labkit.ui.app."
                "labkit.ui.spec."
                "labkit.ui.view."
                "labkit.ui.tool."
                "labkit.ui.diag."
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
                "Apps should use UI5 runtime/layout/control/plot/interaction/debug facades: " + ...
                strjoin(hits, "; "));
        end

        function test_apps_do_not_reimplement_plot_clear(testCase)
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
                "Apps should call labkit.ui.plot.clear instead of reimplementing axes cleanup: " + ...
                strjoin(hits, ", "));
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
