%% Verificarea structurală a constructorilor de modele Simulink în GNU Octave (fără Simulink).
%  Funcțiile add_block / set_param / get_param / add_line / sim sunt înlocuite de un simulator care
%  verifică: căile din bibliotecă, valorile permise ale parametrilor importanți, ordinea parametrilor
%  la DC Machine, porturile existente, intrările nelegate, bornele fizice nelegate și afișează nodurile
%  electrice ale fiecărui model.  Rulare: din simulink/verificare_octave:  octave-cli test_constructori.m
%  (variabila FISIER_REFERINTE, opțională, păstrează simulările de referință între rulări).
aici = fileparts(mfilename('fullpath'));
addpath(fullfile(aici, '..'));
addpath(aici);                         % simulatorul are prioritate față de funcțiile reale
warning('off', 'Octave:shadowed-function');
if exist('FISIER_REFERINTE', 'var') && exist(FISIER_REFERINTE, 'file')
    load(FISIER_REFERINTE);  REFERINTE_CALCULATE = true;
else
    P = parametri_simulink();  Z = simulari(P.S, P.M, P.T);
    Rd = sim_dcdc_comutatie(P.D, P.S.cv.simulare.dcdc);  Ri = sim_incarcare_comutatie(P.C, P.S.cv.simulare.incarcare);
    if exist('FISIER_REFERINTE', 'var'), save('-v7', FISIER_REFERINTE, 'P', 'Z', 'Rd', 'Ri'); end
    REFERINTE_CALCULATE = true;
end
ruleaza_simulink;
