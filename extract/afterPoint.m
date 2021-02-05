function out = afterPoint(str)
%Remove all text before point
%Yohann Thenaisie 20.12.2020

startIndex = strfind(str,'.');
out = str(startIndex+1:end);