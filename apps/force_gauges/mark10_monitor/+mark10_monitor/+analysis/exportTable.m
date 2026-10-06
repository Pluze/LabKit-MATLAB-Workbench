function value = exportTable(curve)
%EXPORTTABLE Three unambiguous columns; strain is dimensionless, stress MPa.
value=table(curve.time_s,curve.strain,curve.stress_MPa, ...
    VariableNames=["Time_s","Strain","Stress_MPa"]);
end
