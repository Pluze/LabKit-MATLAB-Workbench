function [rows, unit] = resultTable(rows, choice)
%RESULTTABLE Scale displayed modulus only; stored slopes remain signed MPa.
% Auto uses one shared unit based on the largest finite absolute modulus.
% Empty/all-zero results use kPa; nonfinite results never choose a scale.
unit=string(choice);
if ~isscalar(unit) || ~any(unit==["Auto","kPa","MPa","GPa"])
    error("mark10_monitor:analysis:InvalidModulusUnit","Choose Auto, kPa, MPa or GPa.");
end
modulus=cell2mat(rows(:,9));
% SI prefix conversions relative to the calculation's N/mm^2 = MPa.
kPaPerMPa=1000; MPaPerGPa=1000;
if unit=="Auto"
    magnitude=max([0;abs(modulus(isfinite(modulus)))]);
    unit="kPa";
    if magnitude>=MPaPerGPa, unit="GPa";
    elseif magnitude>=1, unit="MPa"; end
end
factor=1;
if unit=="kPa", factor=kPaPerMPa;
elseif unit=="GPa", factor=1/MPaPerGPa; end
rows(:,9)=num2cell(modulus*factor);
end
