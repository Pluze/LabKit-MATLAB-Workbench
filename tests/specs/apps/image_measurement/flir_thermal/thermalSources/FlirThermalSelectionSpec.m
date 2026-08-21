classdef FlirThermalSelectionSpec < matlab.unittest.TestCase
    %FLIRTHERMALSELECTIONSPEC Specify FLIR source acquisition behavior.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function declaresABatchFileChooserWithRadiometricFiltering(testCase)
            plan = labkittest.inspectDefinition( ...
                flir_thermal.definition());
            node = plan.Nodes(string({plan.Nodes.Id}) == "thermalFiles");
            config = node.Configuration;

            testCase.verifyEqual(config.SelectionMode, "multiple");
            testCase.verifyEqual(config.ChooseLabel, "Add FLIR files");
            testCase.verifyEqual(config.PathFilterDescription, ...
                "radiometric FLIR image");
            testCase.verifyNotEmpty(config.PathFilter);
        end

        function filtersUnreadableCandidatesBeforeRegisteringSources(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            thermalPath = fullfile(folder, "synthetic_flir.jpg");
            ordinaryPath = fullfile(folder, "ordinary.jpg");
            wrongTypePath = fullfile(folder, "notes.txt");
            testfixtures.thermal.writeRjpeg(thermalPath);
            imwrite(uint8(120 .* ones(5, 6, 3)), ordinaryPath);
            file = fopen(wrongTypePath, "w");
            cleanup = onCleanup(@() fclose(file));
            fprintf(file, "not thermal");
            clear cleanup

            accepted = ...
                flir_thermal.thermalSources.matchesRadiometricFiles( ...
                [string(thermalPath), string(ordinaryPath), ...
                 string(wrongTypePath)]);

            testCase.verifyEqual(accepted, [true false false]);
        end
    end
end
