function B = dimensionare_baterie(Wbat, cel, V, C, P_max)
%DIMENSIONARE_BATERIE Numărul de celule și dispunerea lor (suport P3, slide 9).
%   Wbat  – energia necesară în baterie [Ws] (din CALCUL_P3)
%   cel   – parametrii celulei alese (vezi CELULA_ALEASA)
%   P_max – puterea mecanică maximă la axul mașinii [W] (din CALCUL_P2)
%
%   W_celula = Cap_celula [As] * U_celula [V]      N_celule = Wbat / W_celula
%   celule în serie   -> tensiunea bateriei
%   celule în paralel -> curentul bateriei (și capacitatea)
%   limitare: masa bateriei <= 30 % din masa vehiculului

B.celula = cel;
B.W_celula = cel.Cap_Ah * 3600 * cel.U_nom;          % [Ws]
B.N_min = ceil(Wbat / B.W_celula);                   % numărul minim de celule (energie)

% celule în serie: tensiunea nominală cât mai aproape de ținta de 800 V
B.Ns = round(C.U_bat_tinta / cel.U_nom);
B.U_nom = B.Ns * cel.U_nom;                          % [V]
B.U_max = B.Ns * cel.U_max;                          % [V] celule complet încărcate
B.U_min = B.Ns * cel.U_min;                          % [V] celule descărcate

% ramuri în paralel: din condiția de energie și din condiția de curent
% (curentul cel mai mare apare la tensiunea minimă, bateria aproape descărcată)
B.Np_energie = ceil(B.N_min / B.Ns);
B.P_el_max = P_max / C.eta;                          % [W] puterea electrică cerută bateriei
B.I_bat_nom = B.P_el_max / B.U_nom;                  % [A] la tensiunea nominală
B.I_bat_max = B.P_el_max / B.U_min;                  % [A] la tensiunea minimă (caz defavorabil)
B.Np_curent = ceil(B.I_bat_max / cel.I_max_cont);
B.Np = max(B.Np_energie, B.Np_curent);

B.N = B.Ns * B.Np;                                   % numărul total de celule
B.W_real = B.N * B.W_celula;                         % [Ws] energia instalată
B.W_real_kWh = B.W_real / 3.6e6;
B.Cap_Ah = B.Np * cel.Cap_Ah;                        % [Ah] capacitatea bateriei
B.I_celula = B.I_bat_max / B.Np;                     % [A] pe celulă la P_max și U_min
B.I_celula_nom = B.I_bat_nom / B.Np;                 % [A] pe celulă la P_max și U_nom

% informativ: curentul pe celulă dacă bateria ar livra puterea declarată (documentare)
B.P_doc = V.P_doc;
B.I_celula_doc_nom = V.P_doc / C.eta / B.U_nom / B.Np;
B.I_celula_doc_min = V.P_doc / C.eta / B.U_min / B.Np;

% masa: celule și pachet (celule + carcasă, răcire, BMS, conexiuni)
B.m_celule = B.N * cel.m_kg;                         % [kg]
B.m_pachet = B.m_celule / cel.k_celula_pachet;       % [kg] estimare
B.m_limita = C.k_masa_bat * V.M;                     % [kg]
B.masa_ok_celule = B.m_celule <= B.m_limita;
B.masa_ok_pachet = B.m_pachet <= B.m_limita;
B.procent_celule = B.m_celule / V.M * 100;
B.procent_pachet = B.m_pachet / V.M * 100;
end
