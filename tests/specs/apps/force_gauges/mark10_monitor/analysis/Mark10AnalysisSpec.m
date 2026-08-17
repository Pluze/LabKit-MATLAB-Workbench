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

        function manualRegionUsesOneCorrectedTravelWindowAcrossBranches(testCase)
            travel = [linspace(0, 3, 151), linspace(3, 0, 151)].';
            time = (0:numel(travel)-1).' / 50;
            force = 2 * travel;
            p = parameters("Manual");
            p.manualStart_mm = 0.5;
            p.manualEnd_mm = 1.5;

            result = mark10_monitor.analysis.compute( ...
                time, force, travel, p, "Compression");

            testCase.verifyGreaterThanOrEqual(result.segmentCount, 2);
            testCase.verifyEqual(cell2mat(result.rows(:, 5)), ...
                0.5 * ones(result.segmentCount, 1), ...
                "AbsTol", 1e-12);
            testCase.verifyEqual(cell2mat(result.rows(:, 6)), ...
                1.5 * ones(result.segmentCount, 1), ...
                "AbsTol", 1e-12);
            testCase.verifyEqual(cell2mat(result.rows(:, 9)), ...
                10 * ones(result.segmentCount, 1), ...
                "AbsTol", 1e-10);
        end

        function manualRegionOmitsBranchesThatDoNotCrossTheWindow(testCase)
            travel = [linspace(0, 1, 51), linspace(1, 0, 51)].';
            p = parameters("Manual");
            p.manualStart_mm = 2;
            p.manualEnd_mm = 3;

            result = mark10_monitor.analysis.compute( ...
                (0:numel(travel)-1).' / 50, 2 * travel, travel, ...
                p, "Tension");

            testCase.verifyEmpty(result.fitLines);
            testCase.verifyTrue(all(string(result.rows(:, 11)) == ...
                "Need at least 4 fit points"));
        end

        function manualRegionFitsSparseResolvedBranches(testCase)
            travel = [linspace(0, 20, 10), linspace(20, 0, 10), ...
                linspace(0, 20, 10)].';
            p = parameters("Manual");
            p.manualStart_mm = 5;
            p.manualEnd_mm = 15;

            result = mark10_monitor.analysis.compute( ...
                (0:numel(travel)-1).' / 5, 2 * travel, travel, ...
                p, "Tension");

            testCase.verifyGreaterThanOrEqual(result.segmentCount, 3);
            testCase.verifyTrue(all(cell2mat(result.rows(:, 7)) >= 4));
            testCase.verifyEqual(cell2mat(result.rows(:, 9)), ...
                10 * ones(result.segmentCount, 1), "AbsTol", 1e-10);
            testCase.verifyTrue(all(string(result.rows(:, 11)) == "Accepted"));
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

        function zeroLevelsShiftCoordinatesWithoutChangingModulus(testCase)
            travel = 5 + linspace(0, 3, 151).';
            force = 4 + 2 * (travel - 5);
            time = (0:numel(travel)-1).' / 50;
            unshifted = mark10_monitor.analysis.compute( ...
                time, force, travel, parameters("Automatic"), "Tension");
            shiftedParameters = parameters("Automatic");
            shiftedParameters.forceZero_N = 4;
            shiftedParameters.travelZero_mm = 5;

            shifted = mark10_monitor.analysis.compute( ...
                time, force, travel, shiftedParameters, "Tension");

            testCase.verifyEqual(shifted.plotStrain_percent(1), 0, ...
                "AbsTol", 1e-12);
            testCase.verifyEqual(shifted.plotStress_MPa(1), 0, ...
                "AbsTol", 1e-12);
            testCase.verifyNotEqual(unshifted.plotStrain_percent(1), ...
                shifted.plotStrain_percent(1));
            testCase.verifyEqual(cell2mat(shifted.rows(:, 9)), ...
                cell2mat(unshifted.rows(:, 9)), "AbsTol", 1e-10);
        end

        function rejectsNonfiniteZeroLevels(testCase)
            p = parameters("Automatic");
            p.forceZero_N = NaN;
            testCase.verifyError(@() mark10_monitor.analysis.compute( ...
                (0:20).', (0:20).', (0:20).', p, "Tension"), ...
                "mark10_monitor:analysis:InvalidZeroLevel");
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
            testCase.verifyEqual(exported.ForceZero_N, 0);
            testCase.verifyEqual(exported.TravelZero_mm, 0);
            testCase.verifyEqual(exported.FitMode, "Automatic");
        end

        function applyAndResetShiftBothReplayPlots(testCase)
            resources = containers.Map("KeyType", "char", "ValueType", "any");
            backend = struct( ...
                "setResource", @(scope, id, value, cleanup) ...
                    storeResource(resources, scope, id, value, cleanup), ...
                "getResource", @(scope, id) ...
                    getResource(resources, scope, id));
            context = labkittest.createCallbackContext(backend);
            session = mark10_monitor.createSession(struct(), context);
            playback = containers.Map( ...
                "KeyType", "char", "ValueType", "any");
            playback("time_s") = [0; 1];
            playback("force_N") = [2; 3];
            playback("travel_mm") = [30; 31];
            playback("index") = 2;
            storeResource(resources, "application", ...
                "mark10Playback", playback, []);
            session.playback.loaded = true;
            session.playback.cursor = 2;
            session.playback.count = 2;
            session.analysis.dataSource = "Loaded Recording";
            session.analysis.forceZeroDraft_N = 2;
            session.analysis.travelZeroDraft_mm = 30;
            session.analysis.resultRows = cell(1, 11);

            state = mark10_monitor.analysis.applyZero( ...
                struct("session", session), context);

            testCase.verifyEqual( ...
                state.session.acquisition.plotForce_N, [0; 1]);
            testCase.verifyEqual( ...
                state.session.acquisition.plotTravel_mm, [0; 1]);
            testCase.verifyEqual(playback("force_N"), [2; 3]);
            testCase.verifyEqual(playback("travel_mm"), [30; 31]);
            testCase.verifyEqual(state.session.analysis.forceZero_N, 2);
            testCase.verifyEqual(state.session.analysis.travelZero_mm, 30);
            testCase.verifyEmpty(state.session.analysis.resultRows);

            state = mark10_monitor.analysis.resetZero(state, context);

            testCase.verifyEqual(state.session.analysis.forceZero_N, 0);
            testCase.verifyEqual(state.session.analysis.travelZero_mm, 0);
            testCase.verifyEqual( ...
                state.session.acquisition.plotForce_N, [2; 3]);
            testCase.verifyEqual( ...
                state.session.acquisition.plotTravel_mm, [30; 31]);
            testCase.verifyEqual(state.session.analysis.status, ...
                "Plot force and travel zero levels reset to 0.");
        end

        function sharedPlotShiftIncludesHardwareTravelZero(testCase)
            analysis = parameters("Automatic");
            analysis.forceZero_N = 2;
            analysis.travelZero_mm = 30;

            [force, travel] = mark10_monitor.analysis.shiftPlotData( ...
                [2; 3], [35; 36], analysis, 5);

            testCase.verifyEqual(force, [0; 1]);
            testCase.verifyEqual(travel, [0; 1]);
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

function storeResource(resources, scope, id, value, cleanup)
key = char(string(scope) + "|" + string(id));
resources(key) = struct("Value", value, "Cleanup", cleanup);
end

function value = getResource(resources, scope, id)
key = char(string(scope) + "|" + string(id));
value = resources(key).Value;
end

function value = parameters(mode)
value = struct("gaugeLength_mm", 10, "width_mm", 2, ...
    "thickness_mm", 1, "geometryConfirmed", true, ...
    "forceZero_N", 0, "travelZero_mm", 0, ...
    "fitMode", mode, "manualStart_mm", 0, "manualEnd_mm", 1);
end
