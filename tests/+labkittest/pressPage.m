function pressPage(figureValue,id)
% Activate the same native navigation button used by the operator.
button = findall(figureValue,"Tag",id+".navigate");
button.ButtonPushedFcn(button,[]);
drawnow;
end
