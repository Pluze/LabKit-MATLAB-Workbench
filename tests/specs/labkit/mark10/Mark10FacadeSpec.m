classdef Mark10FacadeSpec < matlab.unittest.TestCase
    %MARK10FACADESPEC Specify offline Mark-10 protocol and facade behavior.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function decodesSynchronizedSamplesAndRejectsContamination(testCase)
            raw = "99.0 N" + newline + "2.500 lbf" + newline + ...
                "0.125 in" + newline;

            sample = labkit.mark10.decodeSample(raw);
            malformed = labkit.mark10.decodeSample( ...
                "2.500 lbf" + newline + "not travel" + newline);

            testCase.verifyTrue(sample.Valid);
            testCase.verifyEqual(sample.Force_N, 11.12055403815125, ...
                "AbsTol", 1e-12);
            testCase.verifyEqual(sample.Travel_mm, 3.175, "AbsTol", 1e-12);
            testCase.verifyEqual(sample.ForceRawValue, 2.5);
            testCase.verifyFalse(malformed.Valid);
        end

        function decodesMixedListAndPreservesUnknownTokens(testCase)
            raw = "1.25 N" + newline + ...
                "V1.00;N;CUR;FLTC3;FLTP1;AOUT25;AOFF5;FULL;" + ...
                "IPOL1;OPOL0;B0;FUTURE7" + newline + "1.26 N";

            settings = labkit.mark10.decodeSettings(raw);

            testCase.verifyEqual(settings.Unit, "N");
            testCase.verifyEqual(settings.Mode, "CUR");
            testCase.verifyEqual(settings.CurrentFilter, 8);
            testCase.verifyEqual(settings.DisplayFilter, 2);
            testCase.verifyEqual(settings.AutoOutput, 25);
            testCase.verifyTrue(settings.InvertPolarity);
            testCase.verifyEqual(settings.UnknownTokens, "FUTURE7");
        end

        function fallsBackToTravelAndGaugeWithoutDisconnecting(testCase)
            state = containers.Map("KeyType", "char", "ValueType", "any");
            state("command") = "";
            state("closed") = false;
            transport = struct( ...
                "Write", @(bytes) Mark10FacadeSpec.writeBytes(state, bytes), ...
                "Flush", @() [], ...
                "ReadUntil", @(lines, seconds) ...
                    Mark10FacadeSpec.readUntil(state, lines, seconds), ...
                "ReadFor", @(seconds) uint8([]), ...
                "Pause", @(seconds) [], ...
                "Close", @() Mark10FacadeSpec.close(state), ...
                "IsOpen", @() ~state("closed"));
            connection = struct( ...
                "Type", "labkit.mark10.connection", "Port", "SYNTHETIC", ...
                "Timeout", 0.01, "Transport", transport, ...
                "Identity", struct(), "Capabilities", struct(), ...
                "Settings", struct(), "RestoreAutoOutput", "AOUT0", ...
                "AcquisitionMode", "Unknown", "SampleCount", uint64(0), ...
                "LastFailure", struct("Status", "", "Message", ""));

            [connection, sample] = labkit.mark10.readSample(connection);

            testCase.verifyTrue(sample.Valid);
            testCase.verifyEqual(sample.AcquisitionMode, "Fallback x + ?C");
            testCase.verifyEqual(sample.Force_N, 2);
            testCase.verifyEqual(sample.Travel_mm, 1);
            testCase.verifyEqual(connection.SampleCount, uint64(1));
            testCase.verifyFalse(state("closed"));
        end

        function publishesStableVersionAndValidatesInputs(testCase)
            info = labkit.mark10.version();

            testCase.verifyEqual(info.name, "labkit.mark10");
            testCase.verifyEqual(info.current, "1.1.1");
            testCase.verifyError(@() labkit.mark10.decodeSample({"bad"}), ...
                "labkit:mark10:InvalidValue");
            testCase.verifyError(@() labkit.mark10.writeSetting( ...
                struct(), "unit", "N"), "labkit:mark10:InvalidConnection");
        end

        function verifiesSilentForceZeroFromDisplayedResolution(testCase)
            state = containers.Map("KeyType", "char", "ValueType", "any");
            state("command") = "";
            state("closed") = false;
            state("zeroMode") = true;
            state("queryCount") = 0;
            transport = struct( ...
                "Write", @(bytes) Mark10FacadeSpec.writeBytes(state, bytes), ...
                "Flush", @() [], ...
                "ReadUntil", @(lines, seconds) ...
                    Mark10FacadeSpec.readUntil(state, lines, seconds), ...
                "ReadFor", @(seconds) uint8([]), "Pause", @(seconds) [], ...
                "Close", @() Mark10FacadeSpec.close(state), ...
                "IsOpen", @() ~state("closed"));
            connection = Mark10FacadeSpec.connectionToken(transport);

            [~, result] = labkit.mark10.zeroForce(connection);

            testCase.verifyTrue(result.Success);
            testCase.verifyEqual(result.Status, ...
                "NO_ACK_BUT_READBACK_CONFIRMED");
            testCase.verifyEqual(result.After_N, 0);
            testCase.verifyEqual(result.Resolution_N, 0.01);
            testCase.verifyEqual(result.Message, "");
        end

        function rejectsTravelZeroWithoutDeviceCommandAccess(testCase)
            state = containers.Map("KeyType", "char", "ValueType", "any");
            state("command") = "";
            transport = struct( ...
                "Write", @(bytes) Mark10FacadeSpec.writeBytes(state, bytes), ...
                "Flush", @() [], ...
                "ReadUntil", @(lines, seconds) ...
                    Mark10FacadeSpec.readUntil(state, lines, seconds), ...
                "ReadFor", @(seconds) uint8([]), "Pause", @(seconds) [], ...
                "Close", @() [], "IsOpen", @() true);
            connection = Mark10FacadeSpec.connectionToken(transport);

            [connection, result] = labkit.mark10.zeroTravel(connection);

            testCase.verifyFalse(result.Success);
            testCase.verifyFalse(result.HardwareApplied);
            testCase.verifyEqual(result.Status, "CURRENT_MODE_UNAVAILABLE");
            testCase.verifyTrue(isnan(result.SoftwareOffset_mm));
            testCase.verifyEqual(state("command"), "p", ...
                "The driver must not send z without confirmed device access.");
            testCase.verifyEqual(connection.LastFailure.Status, ...
                "CURRENT_MODE_UNAVAILABLE");
        end

        function sendsAndVerifiesEsm303TravelZero(testCase)
            state = containers.Map("KeyType", "char", "ValueType", "any");
            state("command") = "";
            state("travelReads") = 0;
            state("sentZ") = false;
            transport = struct( ...
                "Write", @(bytes) Mark10FacadeSpec.travelZeroWrite( ...
                    state, bytes), ...
                "Flush", @() [], ...
                "ReadUntil", @(~, ~) Mark10FacadeSpec.travelZeroRead(state), ...
                "ReadFor", @(~) uint8([]), "Pause", @(~) [], ...
                "Close", @() [], "IsOpen", @() true);
            connection = Mark10FacadeSpec.connectionToken(transport);

            [~, result] = labkit.mark10.zeroTravel(connection);

            testCase.verifyTrue(result.Success);
            testCase.verifyTrue(result.HardwareApplied);
            testCase.verifyTrue(state("sentZ"));
            testCase.verifyEqual(result.After_mm, 0);
            testCase.verifyEqual(result.SoftwareOffset_mm, 0);
        end

        function verifiesTensionPositiveOutputPolarityByReadback(testCase)
            state = containers.Map("KeyType", "char", "ValueType", "any");
            state("command") = "";
            state("inverted") = false;
            transport = struct( ...
                "Write", @(bytes) Mark10FacadeSpec.polarityWrite(state, bytes), ...
                "Flush", @() [], ...
                "ReadUntil", @(~, ~) Mark10FacadeSpec.polarityRead(state), ...
                "ReadFor", @(~) uint8([]), "Pause", @(~) [], ...
                "Close", @() [], "IsOpen", @() true);
            connection = Mark10FacadeSpec.connectionToken(transport);

            [~, settings, result] = labkit.mark10.writeSetting( ...
                connection, "invertPolarity", true);

            testCase.verifyTrue(result.Success);
            testCase.verifyTrue(settings.InvertPolarity);
            testCase.verifyEqual(result.Command, "IPOL1");
        end

        function samplingRequiresTheBackgroundDriverContract(testCase)
            connection = Mark10FacadeSpec.connectionToken(struct( ...
                "Write", @(~) [], "Flush", @() [], ...
                "ReadUntil", @(~, ~) uint8([]), ...
                "ReadFor", @(~) uint8([]), "Pause", @(~) [], ...
                "Close", @() [], "IsOpen", @() true));
            testCase.verifyError(@() labkit.mark10.startSampling( ...
                connection, 1, @() []), "labkit:mark10:InvalidValue");
            testCase.verifyError(@() labkit.mark10.startSampling( ...
                connection, 1, @(~, ~) []), ...
                "labkit:mark10:InvalidConnection");
        end
    end

    methods (Static, Access = private)
        function writeBytes(state, bytes)
            state("command") = string(native2unicode(uint8(bytes(:).'), "UTF-8"));
        end

        function polarityWrite(state, bytes)
            command = strip(string(native2unicode( ...
                uint8(bytes(:).'), "UTF-8")));
            state("command") = erase(command, char(13));
            if state("command") == "IPOL1"
                state("inverted") = true;
            end
        end

        function travelZeroWrite(state, bytes)
            command = strip(string(native2unicode( ...
                uint8(bytes(:).'), "UTF-8")));
            state("command") = erase(command, char(13));
            if state("command") == "z"
                state("sentZ") = true;
            end
        end

        function raw = travelZeroRead(state)
            if state("command") == "p"
                raw = uint8(sprintf('S\r\n'));
            elseif state("command") == "x"
                state("travelReads") = state("travelReads") + 1;
                if state("travelReads") == 1
                    raw = uint8(sprintf('2.00 mm\r\n'));
                else
                    raw = uint8(sprintf('0.00 mm\r\n'));
                end
            else
                raw = uint8([]);
            end
        end

        function raw = polarityRead(state)
            if state("command") ~= "LIST"
                raw = uint8([]);
                return;
            end
            token = "IPOL" + double(state("inverted"));
            raw = uint8(char("V1.00;N;CUR;FLTC0;FLTP0;AOUT0;" + ...
                "AOFF0;FULL;" + token + ";OPOL0" + newline));
        end

        function raw = readUntil(state, ~, ~)
            command = strip(erase(state("command"), char(13)));
            if isKey(state, "zeroMode") && command == "?C"
                count = state("queryCount") + 1;
                state("queryCount") = count;
                if count == 1
                    raw = uint8(sprintf('1.00 N\r\n'));
                else
                    raw = uint8(sprintf('0.00 N\r\n'));
                end
            elseif command == "x"
                raw = uint8(sprintf('1.00 mm\r\n'));
            elseif command == "?C"
                raw = uint8(sprintf('2.00 N\r\n'));
            else
                raw = uint8(sprintf('invalid\r\n'));
            end
        end

        function close(state)
            state("closed") = true;
        end

        function value = connectionToken(transport)
            value = struct( ...
                "Type", "labkit.mark10.connection", "Port", "SYNTHETIC", ...
                "Timeout", 0.01, "Transport", transport, ...
                "Identity", struct(), "Capabilities", struct(), ...
                "Settings", struct(), "RestoreAutoOutput", "AOUT0", ...
                "AcquisitionMode", "Unknown", "SampleCount", uint64(0), ...
                "LastFailure", struct("Status", "", "Message", ""));
        end
    end
end
