classdef Mark10DeviceOperationSpec < matlab.unittest.TestCase
    %MARK10DEVICEOPERATIONSPEC Specify verified device-zero behavior.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function successfulForceZeroUpdatesReadoutAndClearsFailure(testCase)
            command = containers.Map("KeyType", "char", "ValueType", "any");
            command("value") = "";
            command("forceReads") = 0;
            box = containers.Map("KeyType", "char", "ValueType", "any");
            box("connection") = Mark10DeviceOperationSpec.connection(command);
            context = labkittest.createCallbackContext(struct( ...
                "getResource", @(~, ~) box, "alert", @(~, ~) []));
            state = struct("session", struct( ...
                "acquisition", struct("force_N", 5), ...
                "connection", struct("status", "", ...
                    "lastFailure", "Earlier failure")));

            state = mark10_monitor.connection.zeroForce(state, context);

            testCase.verifyEqual(state.session.acquisition.force_N, 0);
            testCase.verifyEqual(state.session.connection.status, ...
                "Force zero verified.");
            testCase.verifyEqual(state.session.connection.lastFailure, "");
        end

        function rejectsTravelZeroWhenDeviceCommandIsUnavailable(testCase)
            command = containers.Map("KeyType", "char", "ValueType", "any");
            command("value") = "";
            command("forceReads") = 0;
            alerts = containers.Map("KeyType", "char", "ValueType", "any");
            alerts("message") = "";
            connection = Mark10DeviceOperationSpec.connection(command);
            box = containers.Map("KeyType", "char", "ValueType", "any");
            box("connection") = connection;
            backend = struct( ...
                "getResource", @(~, ~) box, ...
                "alert", @(message, ~) Mark10DeviceOperationSpec.captureAlert( ...
                    alerts, message));
            context = labkittest.createCallbackContext(backend);
            state = struct("session", struct( ...
                "acquisition", struct( ...
                    "travel_mm", 2, "plotTravel_mm", [1; 2]), ...
                "connection", struct("status", "", "lastFailure", "")));

            state = mark10_monitor.connection.zeroTravel(state, context);

            testCase.verifyEqual(state.session.acquisition.travel_mm, 2);
            testCase.verifyEqual( ...
                state.session.acquisition.plotTravel_mm, [1; 2]);
            testCase.verifySubstring(state.session.connection.lastFailure, ...
                "device zero is unavailable");
            testCase.verifyEqual(command("value"), "p");
            testCase.verifyEqual(alerts("message"), ...
                state.session.connection.lastFailure);
        end
    end

    methods (Static, Access = private)
        function alerts = captureAlert(alerts, message)
            alerts("message") = string(message);
        end

        function value = connection(command)
            transport = struct( ...
                "Write", @(bytes) Mark10DeviceOperationSpec.write(command, bytes), ...
                "Flush", @() [], ...
                "ReadUntil", @(~, ~) Mark10DeviceOperationSpec.read(command), ...
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
            command("value") = strip(erase(string(native2unicode( ...
                uint8(bytes(:).'), "UTF-8")), char(13)));
        end

        function raw = read(command)
            if command("value") == "x"
                raw = uint8(sprintf('2.00 mm\r\n'));
            elseif command("value") == "?C"
                command("forceReads") = command("forceReads") + 1;
                if command("forceReads") == 1
                    raw = uint8(sprintf('5.00 N\r\n'));
                else
                    raw = uint8(sprintf('0.00 N\r\n'));
                end
            else
                raw = uint8([]);
            end
        end
    end
end
