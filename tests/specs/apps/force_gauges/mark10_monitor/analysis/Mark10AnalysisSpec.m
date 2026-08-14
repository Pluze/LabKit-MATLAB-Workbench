classdef Mark10AnalysisSpec < matlab.unittest.TestCase
    %MARK10ANALYSISSPEC Specify branch segmentation and modulus calculations.

    methods (Test, TestTags = {'Contract:scientific', 'Env:headless'})
        function recoversKnownModulusForCyclicLoadingAndRecovery(testCase)
            travel = [linspace(0, 2, 101), linspace(2, 0, 101), ...
                linspace(0, 1.5, 81)].';
            time = (0:numel(travel)-1).' / 50;
            force = 3 * travel;

            result = mark10_monitor.analysis.compute( ...
                time, force, travel, parameters("Automatic"), "Tension");

            moduli = cell2mat(result.rows(:, 9));
            testCase.verifyGreaterThanOrEqual(result.segmentCount, 3);
            testCase.verifyEqual(moduli, 15 * ones(size(moduli)), ...
                "AbsTol", 1e-10);
            testCase.verifyEqual(result.acceptedCount, result.segmentCount);
            testCase.verifyTrue(all(contains(string(result.rows(:, 2)), ...
                "Tension")));
        end

        function manualRegionFitsOnlyTheRequestedBranchDisplacement(testCase)
            travel = linspace(0, 3, 151).';
            time = (0:numel(travel)-1).' / 50;
            force = 2 * travel;
            p = parameters("Manual");
            p.manualStart_mm = 0.5;
            p.manualEnd_mm = 1.5;

            result = mark10_monitor.analysis.compute( ...
                time, force, travel, p, "Compression");

            testCase.verifyEqual(cell2mat(result.rows(1, 5)), 0.5, ...
                "AbsTol", 1e-12);
            testCase.verifyEqual(cell2mat(result.rows(1, 6)), 1.5, ...
                "AbsTol", 1e-12);
            testCase.verifyEqual(cell2mat(result.rows(1, 9)), 10, ...
                "AbsTol", 1e-10);
        end

        function rejectsUnconfirmedGeometry(testCase)
            p = parameters("Automatic");
            p.geometryConfirmed = false;
            testCase.verifyError(@() mark10_monitor.analysis.compute( ...
                (0:20).', (0:20).', (0:20).', p, "Tension"), ...
                "mark10_monitor:analysis:GeometryNotConfirmed");
        end

        function automaticRegionAvoidsALateFractureDrop(testCase)
            travel = linspace(0, 4, 201).';
            force = 2 * travel;
            fracture = travel > 3;
            force(fracture) = 6 - 5.5 * (travel(fracture) - 3);
            force(31) = NaN;

            result = mark10_monitor.analysis.compute( ...
                (0:200).' / 50, force, travel, ...
                parameters("Automatic"), "Tension");

            testCase.verifyEqual(cell2mat(result.rows(1, 9)), 10, ...
                "AbsTol", 1e-9);
            testCase.verifyEqual(string(result.rows(1, 11)), "Accepted");
        end

        function exportsNamedScientificColumns(testCase)
            rows = {1, 'Tension loading', 0, 1, 0.1, 0.8, 20, ...
                2, 10, 0.99, 'Accepted'};
            value = mark10_monitor.analysis.resultTable(rows);
            testCase.verifyEqual(string(value.Properties.VariableNames), ...
                ["Segment", "Phase", "Start_s", "End_s", ...
                "FitStart_mm", "FitEnd_mm", "Points", ...
                "Stiffness_N_per_mm", "YoungsModulus_MPa", ...
                "R_squared", "Status"]);
            exported = mark10_monitor.analysis.exportTable( ...
                rows, parameters("Automatic"));
            testCase.verifyEqual(exported.GaugeLength_mm, 10);
            testCase.verifyEqual(exported.Width_mm, 2);
            testCase.verifyEqual(exported.Thickness_mm, 1);
            testCase.verifyEqual(exported.FitMode, "Automatic");
        end
    end

    methods (Test, TestTags = {'Contract:presentation', 'Env:headless'})
        function redrawIsStatelessAndFitMarkersAreCopyable(testCase)
            figureHandle = figure("Visible", "off");
            cleanup = onCleanup(@() close(figureHandle));
            axesById = struct("stressStrain", axes(figureHandle), ...
                "modulusSummary", axes(figureHandle));
            travel = [linspace(0, 2, 101), linspace(2, 0, 101)].';
            result = mark10_monitor.analysis.compute( ...
                (0:numel(travel)-1).' / 50, 3 * travel, travel, ...
                parameters("Automatic"), "Tension");
            model = struct("strain_percent", result.plotStrain_percent, ...
                "stress_MPa", result.plotStress_MPa, ...
                "fitLines", result.fitLines, "summary", result.summary);

            mark10_monitor.analysis.draw(axesById, model);
            accepted = findobj(axesById.stressStrain, ...
                "DisplayName", "Accepted linear fit");
            testCase.verifyNumElements(accepted, 1);
            testCase.verifyEqual(string(accepted.Marker), "o");
            testCase.verifyEqual(string(accepted.HandleVisibility), "on");
            fitHandles = findobj(axesById.stressStrain, ...
                "Type", "line", "LineWidth", 2);
            testCase.verifyNumElements(fitHandles, numel(result.fitLines));
            testCase.verifyTrue(all(string({fitHandles.HandleVisibility}) == "on"));

            emptyModel = struct("strain_percent", zeros(0, 1), ...
                "stress_MPa", zeros(0, 1), ...
                "fitLines", struct("strain_percent", {}, ...
                    "stress_MPa", {}, "accepted", {}), ...
                "summary", "No current analysis.");
            mark10_monitor.analysis.draw(axesById, emptyModel);
            testCase.verifyEmpty(findobj(axesById.stressStrain, ...
                "DisplayName", "Accepted linear fit"));
            clear cleanup
        end
    end
end

function value = parameters(mode)
value = struct("gaugeLength_mm", 10, "width_mm", 2, ...
    "thickness_mm", 1, "geometryConfirmed", true, ...
    "fitMode", mode, "manualStart_mm", 0, "manualEnd_mm", 1);
end
