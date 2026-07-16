classdef LauncherCatalogGuiTest < matlab.unittest.TestCase
    %LAUNCHERCATALOGGUITEST Verify launcher catalog and documentation access.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function launcher_list_mode_discovers_apps(testCase)
            setupLabKitTestPath();

            apps = labkit_launcher("list");
            info = labkit_launcher("version");

            testCase.verifyTrue(istable(apps), ...
                'labkit_launcher list mode should return a table.');
            testCase.verifyEqual(info.name, "labkit_launcher");
            testCase.verifyMatches(info.version, "^\d+\.\d+\.\d+$");
            testCase.verifyMatches(info.updated, "^\d{4}-\d{2}-\d{2}$");
            testCase.verifyTrue(all(ismember( ...
                ["Command", "DisplayName", "Family", "Visibility", "Folder", ...
                "RelativePath", "Description", "Version", "Updated"], ...
                string(apps.Properties.VariableNames))), ...
                'labkit_launcher list mode should return the app catalog columns.');
            testCase.verifyTrue(all(ismember(apps.Visibility, ["public", "private"])), ...
                'Launcher app catalog visibility should be either public or private.');
            testCase.verifyTrue(any(apps.Visibility == "public"), ...
                'Default checkout app catalog should include public app entries.');
            testCase.verifyTrue(all(strlength(apps.Version) > 0 & strlength(apps.Updated) > 0), ...
                'labkit_launcher list mode should expose app version and update dates.');
            testCase.verifyGreaterThan(height(apps), 0, ...
                'labkit_launcher list mode should discover app entry points.');
        end

        function launcher_documentation_mode_resolves_selected_app_page(testCase)
            setupLabKitTestPath();

            page = string(labkit_launcher( ...
                "documentation", "labkit_DICPreprocess_app"));

            testCase.verifyTrue(isfile(page));
            testCase.verifyTrue(endsWith(replace(page, "\", "/"), ...
                "/site/apps/dic/dic-preprocess.html"));
        end

        function launcher_exposes_selected_app_documentation_action(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            fig = labkit_launcher();
            drawnow;
            h.invokeButton(fig, 'Documentation and History');
            drawnow;

            textAreas = findall(fig, 'Type', 'uitextarea');
            testCase.verifyTrue(any(contains(string(textAreas(1).Value), ...
                'Opened documentation for')));
            clear cleanup
        end
    end
end
