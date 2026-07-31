function [temperatureC, diagnostics] = rawToTemperatureC(raw, calibration, opts)
%RAWTOTEMPERATUREC Convert FLIR raw sensor values to degrees Celsius.
%
% Usage:
%   temperatureC = labkit.thermal.rawToTemperatureC(raw, calibration)
%   temperatureC = labkit.thermal.rawToTemperatureC(raw, calibration, opts)
%   [temperatureC, diagnostics] = labkit.thermal.rawToTemperatureC(...)
%
% Description:
%   Applies the FLIR Planck calibration stored in a radiometric image. The
%   default correction also compensates for emissivity, reflected radiation,
%   atmospheric transmission, and an infrared window. Select "planck-basic"
%   when the raw counts have already been corrected or when only the camera's
%   Planck constants should be applied.
%
% Inputs:
%   raw - Numeric array of raw sensor counts. The output has the same size.
%   calibration - Scalar structure containing the five required Planck fields
%       and, for environmental correction, the fields described below.
%   opts - Optional scalar structure. See Options.
%
% Calibration Fields:
%   PlanckR1 - Required finite scalar from the camera metadata.
%   PlanckB - Required finite scalar from the camera metadata.
%   PlanckF - Required finite scalar from the camera metadata.
%   PlanckO - Required finite scalar from the camera metadata.
%   PlanckR2 - Required finite scalar from the camera metadata.
%   Emissivity - Object emissivity in (0,1]. Default: 1.
%   ObjectDistanceM - Nonnegative camera-to-object distance in metres.
%       Default: 1.
%   ReflectedApparentTemperatureC - Reflected apparent temperature in degrees
%       Celsius. Default: 20.
%   AtmosphericTemperatureC - Atmospheric temperature in degrees Celsius.
%       Default: 20.
%   IRWindowTemperatureC - Infrared-window temperature in degrees Celsius.
%       Defaults to ReflectedApparentTemperatureC.
%   IRWindowTransmission - Infrared-window transmission in (0,1]. Default: 1.
%   RelativeHumidity - Relative humidity as a fraction from 0 to 1 or as a
%       percentage greater than 2. Default: 0.5.
%   AtmosphericTransAlpha1 - First atmospheric alpha coefficient. Default:
%       0.006569.
%   AtmosphericTransAlpha2 - Second atmospheric alpha coefficient. Default:
%       0.01262.
%   AtmosphericTransBeta1 - First atmospheric beta coefficient. Default:
%       -0.002276.
%   AtmosphericTransBeta2 - Second atmospheric beta coefficient. Default:
%       -0.00667.
%   AtmosphericTransX - Atmospheric mixing coefficient. Default: 1.9.
%
% Options:
%   Correction - String scalar selecting the conversion model. "environment"
%       uses the environmental fields and records every fallback value.
%       "planck-basic" uses only the five Planck fields. Default:
%       "environment".
%
% Outputs:
%   temperatureC - Double array in degrees Celsius with the same size as raw.
%       Pixels for which the Planck expression is undefined are NaN.
%   diagnostics - Scalar structure describing the conversion. correction is
%       the selected mode; usedDefaults is true if an environmental fallback
%       was used; defaultedFields lists those fields; parameterSources maps
%       each environmental field to "calibration" or "default"; and message
%       provides a readable summary. In "planck-basic" mode, no environmental
%       fields are consumed and defaultedFields is empty.
%
% Errors:
%   Throws labkit:thermal:MissingCalibration when a required Planck field is
%   absent or not finite, labkit:thermal:InvalidCalibration when a supplied
%   environmental field is outside its physical range, and
%   labkit:thermal:InvalidOptions when Correction is unsupported.
%
% Example:
%   calibration = struct("PlanckR1", 21106.77, "PlanckB", 1501, ...
%       "PlanckF", 1, "PlanckO", -7340, "PlanckR2", 0.012545258);
%   raw = [15000 15500; 16000 16500];
%   [temperatureC, diagnostics] = ...
%       labkit.thermal.rawToTemperatureC(raw, calibration, ...
%       struct("Correction", "planck-basic"));
%
% See also labkit.thermal.readFile,
%   labkit.thermal.renderImage

    if nargin < 3
        opts = struct();
    end
    validateOptionStruct(opts, "Correction");
    mode = string(optionValue(opts, 'Correction', "environment"));
    if ~any(mode == ["environment", "planck-basic"])
        error('labkit:thermal:InvalidOptions', ...
            'Correction must be "environment" or "planck-basic".');
    end
    assertPlanckCalibration(calibration);

    raw = double(raw);
    if mode == "environment"
        [rawObject, diagnostics] = environmentCorrectedRaw(raw, calibration);
    else
        rawObject = raw;
        diagnostics = conversionDiagnostics(mode, strings(0, 1), struct());
    end
    diagnostics.correction = mode;
    temperatureC = planckTemperature(rawObject, calibration);
end

function assertPlanckCalibration(calibration)
    required = ["PlanckR1", "PlanckB", "PlanckF", "PlanckO", "PlanckR2"];
    for k = 1:numel(required)
        field = required(k);
        if ~isfield(calibration, field) || ~isfinite(double(calibration.(field)))
            error('labkit:thermal:MissingCalibration', ...
                'Missing FLIR calibration field: %s', field);
        end
    end
end

function [rawObject, diagnostics] = environmentCorrectedRaw(raw, calibration)
    [parameters, diagnostics] = environmentParameters(calibration);
    E = parameters.Emissivity;
    OD = parameters.ObjectDistanceM;
    RTemp = parameters.ReflectedApparentTemperatureC;
    ATemp = parameters.AtmosphericTemperatureC;
    IRWTemp = parameters.IRWindowTemperatureC;
    IRT = parameters.IRWindowTransmission;
    RH = parameters.RelativeHumidity;
    if RH > 1
        RH = RH / 100;
    end
    ATA1 = parameters.AtmosphericTransAlpha1;
    ATA2 = parameters.AtmosphericTransAlpha2;
    ATB1 = parameters.AtmosphericTransBeta1;
    ATB2 = parameters.AtmosphericTransBeta2;
    ATX = parameters.AtmosphericTransX;
    % Constant: FLIR's water-vapor polynomial estimates atmospheric water
    % content from relative humidity and atmospheric temperature in Celsius.
    vaporPolynomial = [1.5587 0.06939 -0.00027816 0.00000068455];
    h2o = RH .* exp(vaporPolynomial(1) + vaporPolynomial(2) .* ATemp + ...
        vaporPolynomial(3) .* ATemp.^2 + vaporPolynomial(4) .* ATemp.^3);
    h2o = max(0, h2o);
    tau1 = atmosphericTau(OD / 2, h2o, ATA1, ATA2, ATB1, ATB2, ATX);
    tau2 = atmosphericTau(OD / 2, h2o, ATA1, ATA2, ATB1, ATB2, ATX);
    tau1 = clampPositive(tau1, 1);
    tau2 = clampPositive(tau2, 1);

    rawRefl1 = rawFromTemperatureC(RTemp, calibration);
    rawAtm1 = rawFromTemperatureC(ATemp, calibration);
    rawWindow = rawFromTemperatureC(IRWTemp, calibration);
    rawRefl2 = rawFromTemperatureC(RTemp, calibration);
    rawAtm2 = rawFromTemperatureC(ATemp, calibration);

    emissWindow = 1 - IRT;
    reflWindow = 0;
    rawObject = raw ./ E ./ tau1 ./ IRT ./ tau2 - ...
        (1 - E) ./ E .* rawRefl1 - ...
        (1 - tau1) ./ E ./ tau1 .* rawAtm1 - ...
        emissWindow ./ E ./ tau1 ./ IRT .* rawWindow - ...
        reflWindow ./ E ./ tau1 ./ IRT .* rawRefl2 - ...
        (1 - tau2) ./ E ./ tau1 ./ IRT ./ tau2 .* rawAtm2;
end

function [parameters, diagnostics] = environmentParameters(calibration)
    % Constant: these are the documented environmental fallback settings
    % used only when the supplied calibration omits or invalidates a field.
    defaults = struct( ...
        'Emissivity', 1, ...
        'ObjectDistanceM', 1, ...
        'ReflectedApparentTemperatureC', 20, ...
        'AtmosphericTemperatureC', 20, ...
        'IRWindowTemperatureC', NaN, ...
        'IRWindowTransmission', 1, ...
        'RelativeHumidity', 0.5, ...
        'AtmosphericTransAlpha1', defaultAtmosphericCoefficient('alpha1'), ...
        'AtmosphericTransAlpha2', defaultAtmosphericCoefficient('alpha2'), ...
        'AtmosphericTransBeta1', defaultAtmosphericCoefficient('beta1'), ...
        'AtmosphericTransBeta2', defaultAtmosphericCoefficient('beta2'), ...
        'AtmosphericTransX', 1.9);
    fields = string(fieldnames(defaults));
    parameters = struct();
    sources = struct();
    defaultedFields = strings(numel(fields), 1);
    defaultedCount = 0;
    for k = 1:numel(fields)
        field = fields(k);
        fallback = defaults.(field);
        if field == "IRWindowTemperatureC" && ~isfinite(fallback)
            fallback = fieldValue(parameters, 'ReflectedApparentTemperatureC', 20);
        end
        validateEnvironmentalField(calibration, field);
        [value, usedDefault] = scalarField(calibration, field, fallback);
        parameters.(field) = value;
        if usedDefault
            sources.(field) = "default";
            defaultedCount = defaultedCount + 1;
            defaultedFields(defaultedCount) = field;
        else
            sources.(field) = "calibration";
        end
    end
    defaultedFields = defaultedFields(1:defaultedCount);
    diagnostics = conversionDiagnostics("environment", defaultedFields, sources);
end

function validateEnvironmentalField(calibration, field)
    if ~isfield(calibration, field)
        return;
    end
    value = calibration.(field);
    validScalar = isnumeric(value) && isscalar(value) && isfinite(double(value));
    switch field
        case {"Emissivity", "IRWindowTransmission"}
            valid = validScalar && double(value) > 0 && double(value) <= 1;
        case "ObjectDistanceM"
            valid = validScalar && double(value) >= 0;
        case "RelativeHumidity"
            valid = validScalar && double(value) >= 0 && double(value) <= 100;
        otherwise
            return;
    end
    if ~valid
        error('labkit:thermal:InvalidCalibration', ...
            'Invalid FLIR environmental calibration field: %s.', field);
    end
end

function value = defaultAtmosphericCoefficient(name)
    % Constant: FLIR radiometric atmospheric transmission coefficients used
    % when a file or caller does not provide camera-specific values.
    coefficients = struct( ...
        'alpha1', 0.006569, ...
        'alpha2', 0.01262, ...
        'beta1', -0.002276, ...
        'beta2', -0.00667);
    value = coefficients.(char(name));
end

function diagnostics = conversionDiagnostics(correction, defaultedFields, sources)
    usedDefaults = ~isempty(defaultedFields);
    if usedDefaults
        message = "Temperature correction used defaults for: " + ...
            strjoin(defaultedFields, ", ") + ".";
    else
        message = "Temperature correction used supplied calibration parameters.";
    end
    diagnostics = struct( ...
        'available', true, ...
        'correction', string(correction), ...
        'usedDefaults', usedDefaults, ...
        'defaultedFields', defaultedFields, ...
        'parameterSources', sources, ...
        'message', message);
end

function tau = atmosphericTau(distancePart, h2o, alpha1, alpha2, beta1, beta2, x)
    distanceRoot = sqrt(max(0, distancePart));
    h2oRoot = sqrt(max(0, h2o));
    tau = x .* exp(-distanceRoot .* (alpha1 + beta1 .* h2oRoot)) + ...
        (1 - x) .* exp(-distanceRoot .* (alpha2 + beta2 .* h2oRoot));
end

function raw = rawFromTemperatureC(temperatureC, calibration)
    % Constant: 273.15 is the exact Celsius-to-Kelvin zero-point offset.
    kelvinOffsetC = 273.15;
    kelvin = double(temperatureC) + kelvinOffsetC;
    raw = calibration.PlanckR1 ./ ...
        (calibration.PlanckR2 .* (exp(calibration.PlanckB ./ kelvin) - ...
        calibration.PlanckF)) - calibration.PlanckO;
end

function temperatureC = planckTemperature(rawObject, calibration)
    denominator = calibration.PlanckR2 .* (rawObject + calibration.PlanckO);
    argument = calibration.PlanckR1 ./ denominator + calibration.PlanckF;
    % Constant: 273.15 is the exact Celsius-to-Kelvin zero-point offset.
    kelvinOffsetC = 273.15;
    temperatureC = calibration.PlanckB ./ log(argument) - kelvinOffsetC;
    temperatureC(~isfinite(temperatureC) | argument <= 0 | denominator <= 0) = NaN;
end

function [value, usedDefault] = scalarField(calibration, field, defaultValue)
    value = defaultValue;
    usedDefault = true;
    if isfield(calibration, field) && isscalar(calibration.(field)) && ...
            isfinite(double(calibration.(field)))
        value = double(calibration.(field));
        usedDefault = false;
    end
end

function value = clampPositive(value, fallback)
    value = double(value);
    if ~isfinite(value) || value <= 0
        value = fallback;
    end
end

function value = fieldValue(S, field, defaultValue)
    value = defaultValue;
    if isfield(S, field)
        value = S.(field);
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end
