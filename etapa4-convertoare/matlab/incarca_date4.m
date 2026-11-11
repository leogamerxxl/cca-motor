function S = incarca_date4()
%INCARCA_DATE4 Datele pentru P5-P6: rezultatele etapelor 2 și 3 și ipotezele convertoarelor.
%   S – structura din etapa 3 (INCARCA_DATE) completată cu:
%   S.M  – parametrii unui motor (model MCC echivalent, IDENTIFICARE_MCC)
%   S.T  – tema de proiect (TEMA_PROIECT)
%   S.cv – ipotezele convertoarelor (../date/convertoare.json)

aici = fileparts(mfilename('fullpath'));
addpath(fullfile(aici, '..', '..', 'etapa3-tema-motor', 'matlab'));
S = incarca_date();
S.M = identificare_mcc(S.mot, S.ip);
S.T = tema_proiect(S, S.M);
S.cv = jsondecode(fileread(fullfile(aici, '..', 'date', 'convertoare.json')));
end
