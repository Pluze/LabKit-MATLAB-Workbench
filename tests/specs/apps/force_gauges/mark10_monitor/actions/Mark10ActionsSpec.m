classdef Mark10ActionsSpec < matlab.unittest.TestCase
    %MARK10ACTIONSSPEC Specify device-only zero and manual read behavior.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function rejectsTravelZeroWhenDeviceCommandIsUnavailable(testCase)
            command = containers.Map("KeyType", "char", "ValueType", "any");
            command("value") = "";
            alerts = containers.Map("KeyType", "char", "ValueType", "any");
            alerts("message") = "";
            connection = Mark10ActionsSpec.connection(command);
            box = containers.Map("KeyType", "char", "ValueType", "any");
            box("connection") = connection;
            backend = struct( ...
                "getResource", @(~, ~) box, ...
                "alert", @(message, ~) Mark10ActionsSpec.captureAlert( ...
                    alerts, message));
            context = labkittest.createCallbackContext(backend);
            state = struct("session", struct( ...
                "acquisition", struct( ...
                    "travel_mm", 2, "plotTravel_mm", [1; 2]), ...
                "connection", struct("status", "", "lastFailure", "")));

            state = mark10_monitor.actions.zeroTravel(state, context);

            testCase.verifyEqual(state.session.acquisition.travel_mm, 2);
            testCase.verifyEqual( ...
                state.session.acquisition.plotTravel_mm, [1; 2]);
            testCase.verifySubstring(state.session.connection.lastFailure, ...
                "device zero is unavailable");
            testCase.verifyEqual(command("value"), "p");
            testCase.verifyEqual(alerts("message"), ...
                state.session.connection.lastFailure);
        end

        function readsOnceWithoutStartingOrRetainingMonitoring(testCase)
            command = containers.Map("KeyType", "char", "ValueType", "any");
            command("value") = "";
            box = containers.Map("KeyType", "char", "ValueType", "any");
            box("connection") = Mark10ActionsSpec.connection(command);
            context = labkittest.createCallbackContext(struct( ...
                "getResource", @(~, ~) box, "alert", @(~, ~) []));
            state = struct("session", struct( ...
                "acquisition", struct("monitoring", false, ...
                    "sampleCount", 7, "force_N", NaN, "travel_mm", NaN), ...
                "connection", struct("status", "", "lastFailure", "", ...
                    "acquisitionMode", "Unknown")));

            state = mark10_monitor.actions.readOnce(state, context);

            testCase.verifyEqual(state.session.acquisition.force_N, 1);
            testCase.verifyEqual(state.session.acquisition.travel_mm, 2);
            testCase.verifyEqual(state.session.acquisition.sampleCount, 7, ...
                "A manual read must not become monitoring data.");
            testCase.verifyEqual(state.session.connection.status, ...
                "Manual device reading updated.");
        end
    end

    methods (Static, Access = private)
        function alerts = captureAlert(alerts, message)
            alerts("message") = string(message);
        end

        function value = connection(command)
            transport = struct( ...
                "Write", @(bytes) Mark10ActionsSpec.write(command, bytes), ...
                "Flush", @() [], ...
                "ReadUntil", @(~, ~) Mark10ActionsSpec.read(command), ...
                "ReadFor", @(~) uint8([]), "Pause", @(~) [], ...
                "Close", @() [], "IsOpen", @() true);
            value = struct("Type", "labkit.mark10.connection", ...
                "Port", "SYNTHETIC", "Timeout", 0.01, ...
                "Transport", transport, "Identity", struct(), ...
                "Capabilities", struct(), "Settings", struct(), ...
                "RestoreAutoOutput", "AOUT0", "AcquisitionMode", "Unknown", ...
                "SampleCount", uint64(0), ...
                "LastFailure", struct("Status", "", "Message", ""));
        end

        function command = write(command, bytes)
            command("value") = string(native2unicode(uint8(bytes(:).'), "UTF-8"));
        end

        function raw = read(command)
            if command("value") == "n"
                raw = uint8(sprintf('1.00 N\r\n2.00 mm\r\n'));
            elseif command("value") == "x"
                raw = uint8(sprintf('2.00 mm\r\n'));
            else
                raw = uint8([]);
            end
        end
    end
end
