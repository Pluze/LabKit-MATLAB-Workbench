classdef LauncherCatalogGuiTest < matlab.unittest.TestCase
    %LAUNCHERCATALOGGUITEST Verify launcher catalog and version history access.

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

        function launcher_history_mode_returns_structured_app_records(testCase)
            setupLabKitTestPath();

            records = labkit_launcher("history", "labkit_DICPreprocess_app");

            testCase.verifyNotEmpty(records);
            testCase.verifyTrue(all(string({records.schema}) == "1"));
            testCase.verifyTrue(any(string({records.id}) == ...
                "LK-20260713-dic-rigid-point-editor"));
            transitions = strings(1, 0);
            for k = 1:numel(records)
                components = records(k).components;
                index = find(string({components.name}) == ...
                    "labkit_DICPreprocess_app", 1);
                if ~isempty(index)
                    transitions(end + 1) = components(index).fromVersion + ...
                        " -> " + components(index).toVersion;
                end
            end
            testCase.verifyTrue(any(transitions == "1.3.6 -> 1.4.0"));
        end

        function launcher_opens_selected_app_version_history(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            fig = labkit_launcher();
            drawnow;
            h.invokeButton(fig, 'Version History');
            drawnow;

            viewers = findall(groot, 'Type', 'figure', '-regexp', ...
                'Name', 'Version History$');
            testCase.verifyNotEmpty(viewers, ...
                'Version History should open for the selected launcher app.');
            tables = findall(viewers(1), 'Type', 'uitable');
            textAreas = findall(viewers(1), 'Type', 'uitextarea');
            testCase.verifyNotEmpty(tables);
            testCase.verifyGreaterThan(size(tables(1).Data, 1), 0);
            testCase.verifyTrue(any(contains(string(textAreas(1).Value), ...
                'Change ID:')));
            clear cleanup
        end
    end
end
