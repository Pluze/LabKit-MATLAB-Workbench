function result = runTTest(vectorA, vectorB, options)
%RUNTTEST Run one independent Welch, pooled, or paired t-test.
%
% Usage:
%   result = ttest_wizard.testRun.runTTest(vectorA, vectorB, options)
%
% Description:
%   Calculates one App-owned t-test with Base MATLAB beta functions. Difference
%   direction is always A minus B. Scientific validation failures return a
%   result row with ok=false and a stable status instead of fabricating a
%   statistic.
%
% Inputs:
%   vectorA - Finite numeric vector with at least two values.
%   vectorB - Finite numeric vector with at least two values.
%   options - Scalar struct with method, alternative, alpha, labelA, and labelB.
%       method accepts a label from testRun.choices or welch, pooled, or paired.
%       alternative accepts a choice label or two_sided, greater, or less.
%       alpha is a finite scalar strictly between zero and one.
%
% Outputs:
%   result - Scalar struct created by emptyResult. Successful results include
%       vector snapshots, summaries, A-minus-B estimate and confidence bounds,
%       standard error, t statistic, degrees of freedom, and p-value.
%
% Units:
%   A and B must use the same measurement unit. Means, standard deviations,
%   the A-minus-B estimate, standard error, and confidence bounds retain that
%   unit. The t statistic, degrees of freedom, and p-value are dimensionless.
%
% Assumptions:
%   Independent tests require observations that are independent within and
%   between A and B. The pooled method additionally assumes equal population
%   variances. The paired method requires displayed A(k) and B(k) to describe
%   the same experimental unit; it analyzes A(k)-B(k). Test choice and
%   independence remain the caller's scientific responsibility.
%
% Failure Behavior:
%   Invalid options throw ttest_wizard:InvalidTestOptions. Nonfinite vectors,
%   sample sizes below two, unequal paired lengths, or zero standard error
%   return ok=false with status invalid_input, insufficient_n, unequal_pairs,
%   or zero_standard_error.
%
% Example:
%   options = struct( ...
%       "method", "welch", ...
%       "alternative", "two_sided", ...
%       "alpha", 0.05, ...
%       "labelA", "Condition A", ...
%       "labelB", "Condition B");
%   result = ttest_wizard.testRun.runTTest( ...
%       [1.2 1.4 1.3 1.5], [1.8 1.7 2.0 1.9 1.6], options);
%   assert(result.ok)
%
% See also ttest_wizard.testRun.choices,
%   ttest_wizard.testRun.emptyResult

    result = ttest_wizard.testRun.emptyResult();
    [methodLabel, methodToken, alternativeLabel, alternativeToken, ...
        alpha, labelA, labelB] = validateOptions(options);
    result.method = methodLabel;
    result.methodToken = methodToken;
    result.alternative = alternativeLabel;
    result.alternativeToken = alternativeToken;
    result.alpha = alpha;
    result.labelA = labelA;
    result.labelB = labelB;

    if ~isnumeric(vectorA) || ~isvector(vectorA) || ...
            ~isnumeric(vectorB) || ~isvector(vectorB)
        result.status = "invalid_input";
        result.message = "A and B must be numeric vectors.";
        return;
    end
    vectorA = double(vectorA(:));
    vectorB = double(vectorB(:));
    result.vectorA = vectorA;
    result.vectorB = vectorB;
    result.nA = numel(vectorA);
    result.nB = numel(vectorB);
    if any(~isfinite(vectorA)) || any(~isfinite(vectorB))
        result.status = "invalid_input";
        result.message = "A and B must contain only finite numbers.";
        return;
    end
    if result.nA < 2 || result.nB < 2
        result.status = "insufficient_n";
        result.message = "A and B each need at least two numeric values.";
        return;
    end

    result.meanA = mean(vectorA);
    result.sdA = std(vectorA, 0);
    result.meanB = mean(vectorB);
    result.sdB = std(vectorB, 0);
    if methodToken == "paired"
        if result.nA ~= result.nB
            result.status = "unequal_pairs";
            result.message = sprintf( ...
                'A has %d values and B has %d; a paired test needs equal lengths.', ...
                result.nA, result.nB);
            return;
        end
        differences = vectorA - vectorB;
        result.nPairs = numel(differences);
        result.meanDifference = mean(differences);
        result.standardError = std(differences, 0) / sqrt(result.nPairs);
        result.degreesOfFreedom = result.nPairs - 1;
    elseif methodToken == "pooled"
        result.meanDifference = result.meanA - result.meanB;
        result.degreesOfFreedom = result.nA + result.nB - 2;
        pooledVariance = ((result.nA - 1) * var(vectorA, 0) + ...
            (result.nB - 1) * var(vectorB, 0)) / ...
            result.degreesOfFreedom;
        result.standardError = sqrt(pooledVariance * ...
            (1 / result.nA + 1 / result.nB));
    else
        result.meanDifference = result.meanA - result.meanB;
        varianceA = var(vectorA, 0) / result.nA;
        varianceB = var(vectorB, 0) / result.nB;
        varianceSum = varianceA + varianceB;
        result.standardError = sqrt(varianceSum);
        result.degreesOfFreedom = varianceSum^2 / ( ...
            varianceA^2 / (result.nA - 1) + ...
            varianceB^2 / (result.nB - 1));
    end

    if ~isfinite(result.standardError) || result.standardError <= 0 || ...
            ~isfinite(result.degreesOfFreedom) || ...
            result.degreesOfFreedom <= 0
        result.status = "zero_standard_error";
        result.message = ...
            "The selected data have no estimable positive standard error.";
        return;
    end

    result.tStatistic = result.meanDifference / result.standardError;
    cdfValue = studentTCdf(result.tStatistic, result.degreesOfFreedom);
    switch alternativeToken
        case "greater"
            result.pValue = 1 - cdfValue;
            critical = ttest_wizard.testRun.studentTQuantile(1 - alpha, ...
                result.degreesOfFreedom);
            result.ciLower = result.meanDifference - ...
                critical * result.standardError;
            result.ciUpper = Inf;
        case "less"
            result.pValue = cdfValue;
            critical = ttest_wizard.testRun.studentTQuantile(1 - alpha, ...
                result.degreesOfFreedom);
            result.ciLower = -Inf;
            result.ciUpper = result.meanDifference + ...
                critical * result.standardError;
        otherwise
            result.pValue = 2 * min(cdfValue, 1 - cdfValue);
            critical = ttest_wizard.testRun.studentTQuantile(1 - alpha / 2, ...
                result.degreesOfFreedom);
            result.ciLower = result.meanDifference - ...
                critical * result.standardError;
            result.ciUpper = result.meanDifference + ...
                critical * result.standardError;
    end
    result.pValue = min(1, max(0, result.pValue));
    result.ok = true;
    result.status = "ok";
    result.message = "Test completed.";
end

function [methodLabel, methodToken, alternativeLabel, alternativeToken, ...
        alpha, labelA, labelB] = validateOptions(options)
    assert(isstruct(options) && isscalar(options) && ...
        all(isfield(options, ...
        {'method', 'alternative', 'alpha', 'labelA', 'labelB'})), ...
        'ttest_wizard:InvalidTestOptions', ...
        'Test options are incomplete.');
    choices = ttest_wizard.testRun.choices();
    [methodLabel, methodToken] = resolveChoice( ...
        options.method, choices.methodLabels, choices.methodTokens, "method");
    [alternativeLabel, alternativeToken] = resolveChoice( ...
        options.alternative, choices.alternativeLabels, ...
        choices.alternativeTokens, "alternative");
    alpha = double(options.alpha);
    assert(isnumeric(options.alpha) && isscalar(options.alpha) && ...
        isfinite(alpha) && alpha > 0 && alpha < 1, ...
        'ttest_wizard:InvalidTestOptions', ...
        'Alpha must be a finite scalar between zero and one.');
    labelA = scalarLabel(options.labelA, "A");
    labelB = scalarLabel(options.labelB, "B");
end

function [label, token] = resolveChoice(value, labels, tokens, name)
    value = string(value);
    assert(isscalar(value), 'ttest_wizard:InvalidTestOptions', ...
        'Test %s must be scalar text.', name);
    index = find(labels == value | tokens == value, 1);
    assert(~isempty(index), 'ttest_wizard:InvalidTestOptions', ...
        'Unsupported test %s "%s".', name, value);
    label = labels(index);
    token = tokens(index);
end

function value = scalarLabel(value, fallback)
    value = strip(string(value));
    assert(isscalar(value), 'ttest_wizard:InvalidTestOptions', ...
        'Vector labels must be scalar text.');
    if strlength(value) == 0
        value = fallback;
    end
end

function probability = studentTCdf(value, degreesOfFreedom)
    betaArgument = degreesOfFreedom / ...
        (degreesOfFreedom + value^2);
    tail = 0.5 * betainc(betaArgument, ...
        degreesOfFreedom / 2, 0.5);
    if value >= 0
        probability = 1 - tail;
    else
        probability = tail;
    end
end
