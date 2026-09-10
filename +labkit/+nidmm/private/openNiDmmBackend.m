function backend = openNiDmmBackend(resource)
% Open one NI-DMM session and return repository-owned operation closures.
% Secondary-runtime facade boundary: user-installed NI .NET runtime.
status = niDmmAvailability();
if ~status.Available
    throwAvailability(status);
end
try
    session = NationalInstruments.ModularInstruments.NIDmm.NIDmm( ...
        char(resource), true, false);
catch cause
    exception = vendorFailure("labkit:nidmm:ConnectionFailed", ...
        "Could not open the NI-DMM resource. Confirm its NI MAX name and exclusive availability.", ...
        cause);
    throwAsCaller(addCause(exception, cause));
end
closed = false;
measurementPeriod_s = NaN;
startedAtUTC = NaT(1, "TimeZone", "UTC");
requestedPeriod_s = NaN;
sequence = 0;
backend = struct( ...
    "Model", string(session.DriverIdentity.InstrumentModel), ...
    "DriverVersion", status.DriverVersion, ...
    "configure", @configureBackend, ...
    "read", @readBackend, ...
    "startBuffered", @startBuffered, ...
    "fetchAvailable", @fetchAvailable, ...
    "measurementPeriod", @getMeasurementPeriod, ...
    "stopBuffered", @stopBuffered, ...
    "close", @closeBackend);

    function actualRange = configureBackend(mode, requestedRange, digits)
        requireOpen();
        measurementFunction = measurementFunctionFor(mode);
        try
            if isstring(requestedRange) && requestedRange == "auto"
                restoreImmediateTriggers();
                session.ConfigureMeasurementDigits(measurementFunction, ...
                    NationalInstruments.ModularInstruments.NIDmm.DmmAuto.On, digits);
                session.Measurement.Read();
                actualRange = double(session.AutoRangeValue);
                if ~(isscalar(actualRange) && isfinite(actualRange) && actualRange > 0)
                    error("labkit:nidmm:ConfigurationFailed", ...
                        "NI-DMM did not resolve a usable automatic range.");
                end
            else
                actualRange = double(requestedRange);
            end
            session.ConfigureMeasurementDigits( ...
                measurementFunction, actualRange, digits);
            measurementPeriod_s = double(session.MeasurementPeriod);
        catch cause
            if cause.identifier == "labkit:nidmm:ConfigurationFailed"
                rethrow(cause);
            end
            exception = vendorFailure("labkit:nidmm:ConfigurationFailed", ...
                "NI-DMM rejected the requested measurement mode, range, or resolution.", ...
                cause);
            throwAsCaller(addCause(exception, cause));
        end
    end

    function result = readBackend()
        requireOpen();
        requestedAt = datetime("now", "TimeZone", "UTC");
        try
            value = double(session.Measurement.Read());
        catch cause
            exception = vendorFailure("labkit:nidmm:ReadFailed", ...
                "NI-DMM could not complete the measurement.", cause);
            throwAsCaller(addCause(exception, cause));
        end
        receivedAt = datetime("now", "TimeZone", "UTC");
        result = struct("Value", value, ...
            "TimestampUTC", requestedAt + (receivedAt - requestedAt) / 2, ...
            "ReceivedAtUTC", receivedAt, ...
            "TimeUncertainty_s", seconds(receivedAt - requestedAt) / 2);
    end

    function timing = startBuffered(period_s)
        requireOpen();
        if ~isfinite(measurementPeriod_s)
            error("labkit:nidmm:NotConfigured", ...
                "Configure the NI-DMM connection before starting acquisition.");
        end
        acquisitionPoints = int32(10000000);
        % Keep enough driver-side headroom for timer jitter across slow and
        % fast 4065 resolutions while MATLAB drains completed batches.
        deliveryBufferSamples = int32(100000);
        try
            session.Trigger.MultiPoint.BufferSize = deliveryBufferSamples;
            session.Trigger.MultiPoint.Configure(int32(1), ...
                acquisitionPoints, ...
                NationalInstruments.ModularInstruments.NIDmm.DmmSampleTrigger.Interval, ...
                NationalInstruments.PrecisionTimeSpan(period_s));
            before = datetime("now", "TimeZone", "UTC");
            session.Measurement.Initiate();
            after = datetime("now", "TimeZone", "UTC");
        catch cause
            exception = vendorFailure("labkit:nidmm:AcquisitionFailed", ...
                "NI-DMM could not start buffered acquisition.", cause);
            throwAsCaller(addCause(exception, cause));
        end
        startedAtUTC = before + (after - before) / 2;
        requestedPeriod_s = period_s;
        sequence = 0;
        timing = struct("StartedAtUTC", startedAtUTC, ...
            "RequestedPeriod_s", requestedPeriod_s, ...
            "MeasurementPeriod_s", measurementPeriod_s, ...
            "StartUncertainty_s", seconds(after - before) / 2);
    end

    function batch = fetchAvailable()
        requireOpen();
        try
            [acquisitionStatus, backlog] = ReadStatus(session.Measurement);
            acquisitionStatus = string(acquisitionStatus);
            backlog = double(backlog);
            values = zeros(0, 1);
            if backlog > 0
                values = double(session.Measurement.FetchMultiPoint( ...
                    NationalInstruments.PrecisionTimeSpan(0), int32(backlog)));
                values = values(:);
            end
        catch cause
            exception = vendorFailure("labkit:nidmm:ReadFailed", ...
                "NI-DMM buffered acquisition failed.", cause);
            throwAsCaller(addCause(exception, cause));
        end
        firstSequence = sequence + 1;
        sequence = sequence + numel(values);
        batch = struct("Values", values, "Status", acquisitionStatus, ...
            "FirstSequence", firstSequence, ...
            "ReceivedAtUTC", datetime("now", "TimeZone", "UTC"));
    end

    function stopBuffered()
        if closed
            return;
        end
        try
            session.Measurement.Abort();
        catch
        end
        try
            restoreImmediateTriggers();
        catch
        end
    end

    function value = getMeasurementPeriod()
        value = measurementPeriod_s;
    end

    function closeBackend()
        if closed
            return;
        end
        stopBuffered();
        try
            session.Close();
        catch
        end
        closed = true;
        session = [];
    end

    function requireOpen()
        if closed || isempty(session)
            error("labkit:nidmm:Disconnected", ...
                "The NI-DMM connection is closed.");
        end
    end

    function restoreImmediateTriggers()
        session.Trigger.Source = ...
            NationalInstruments.ModularInstruments.NIDmm.DmmTriggerSource.Immediate;
        session.Trigger.MultiPoint.SampleTrigger = ...
            NationalInstruments.ModularInstruments.NIDmm.DmmSampleTrigger.Immediate;
    end
end

function exception = vendorFailure(id, message, cause)
token = regexp(string(cause.message), "Error code:\s*(-?\d+)", ...
    "tokens", "once");
if ~isempty(token)
    message = compose("%s NI error %s.", extractBefore(message, ...
        strlength(message)), string(token{1}));
end
exception = MException(id, "%s", message);
end

function value = measurementFunctionFor(mode)
switch mode
    case "dc_voltage"
        value = NationalInstruments.ModularInstruments.NIDmm.DmmMeasurementFunction.DCVolts;
    case "ac_voltage"
        value = NationalInstruments.ModularInstruments.NIDmm.DmmMeasurementFunction.ACVolts;
    case "dc_current"
        value = NationalInstruments.ModularInstruments.NIDmm.DmmMeasurementFunction.DCCurrent;
    case "ac_current"
        value = NationalInstruments.ModularInstruments.NIDmm.DmmMeasurementFunction.ACCurrent;
    case "resistance_2wire"
        value = NationalInstruments.ModularInstruments.NIDmm.DmmMeasurementFunction.TwoWireResistance;
    case "resistance_4wire"
        value = NationalInstruments.ModularInstruments.NIDmm.DmmMeasurementFunction.FourWireResistance;
    case "diode"
        value = NationalInstruments.ModularInstruments.NIDmm.DmmMeasurementFunction.Diode;
    otherwise
        error("labkit:nidmm:InvalidMode", ...
            "Unsupported NI-DMM measurement mode: %s.", mode);
end
end

function throwAvailability(status)
switch status.Status
    case "unsupported_platform"
        id = "labkit:nidmm:UnsupportedPlatform";
    case "driver_incompatible"
        id = "labkit:nidmm:DriverIncompatible";
    otherwise
        id = "labkit:nidmm:DriverMissing";
end
throwAsCaller(MException(id, "%s", status.Message));
end
