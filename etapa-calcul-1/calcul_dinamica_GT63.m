%% CCA - Etapa 1 de calcul: dinamica longitudinala a vehiculului
% Mercedes-AMG GT 63 4MATIC+ 4-Door Coupe (versiunea de serie a Concept AMG GT XX)
% Relatiile (1)-(50) din "Notiuni generale de dinamica vehiculului" (curs CCA C1, L. Popescu, UPB).
% Ruleaza in MATLAB sau GNU Octave. Aceleasi date si rezultate ca in CCA_Calcul1_Dinamica_GT63.xlsx.
clear; clc;

%% 1. Date de intrare
% Vehicul (oficial: Mercedes-Benz Media, comunicat de lansare 20.05.2026)
M_DIN   = 2460;          % masa proprie DIN [kg]
m_sofer = 75;            % sofer, conventia UE [kg]
M       = M_DIN + m_sofer;   % masa de calcul [kg]
Cx      = 0.22;          % coeficient de rezistenta aerodinamica [-]
S       = 2.44;          % aria frontala [m^2]
T_max   = 2000;          % cuplul maxim al sistemului (la arborii motoarelor) [N*m]
P_vf    = 860e3;         % puterea de varf, Launch Control [W]
P_cont  = 530e3;         % puterea continua [W]
v_max   = 300;           % viteza maxima, limitata electronic [km/h]
t_acc   = 2.4;           % 0-100 km/h oficial [s]
t_200   = 6.8;           % 0-200 km/h oficial [s]

% Roata si transmisie (ipoteze - valorile nu sunt publicate)
D_jant  = 21;            % janta [inch]
B_anv   = 295;           % latimea anvelopei 295/30 R21 [mm]
h_rap   = 0.30;          % raport de aspect [-]
k_def   = 0.97;          % raza dinamica / raza libera [-]
r_w     = k_def*(D_jant*25.4/2 + B_anv*h_rap)/1000;   % raza dinamica [m]
n_m_vmax = 13000;        % turatia motoarelor spate la v_max (oficial: "peste 13 000") [rot/min]
i_g     = n_m_vmax / (v_max/3.6/(2*pi*r_w)*60);       % raport de transmitere estimat [-]
eta     = 0.95;          % randament transmisie motor -> roata [-]
delta   = 1.0;           % coeficientul maselor in rotatie, rel. (23) [-]

% Mediu si drum (curs C1)
g       = 9.81;          % [m/s^2]
rho     = 1.225;         % densitatea aerului, atmosfera standard [kg/m^3]
f       = 0.012;         % rezistenta la rulare, asfalt uscat normal [-]
mu      = 0.85;          % aderenta, asfalt uscat (0,80-0,90) [-]
mu_perf = 1.20;          % aderenta, anvelope de performanta (ipoteza) [-]

% Cerinte de calcul
v_acc   = 100;           % [km/h]
a_med   = v_acc/3.6/t_acc;   % acceleratia medie 0-100 km/h [m/s^2]
p_1     = 10;  v_p1 = 100;   % rampa 10 % la 100 km/h
p_max   = 30;            % pornire pe panta de 30 %

%% 2. Regimuri caracteristice
nume  = {'S1  v_max, drum orizontal', 'S2a 0-100: pornire', 'S2b 0-100: la 100 km/h', ...
         'S3  rampa 10% la 100 km/h', 'S4  pornire pe 30%'};
v_kmh = [v_max 0 v_acc v_p1 0];
p     = [0 0 0 p_1 p_max];            % panta [%]
a     = [0 a_med a_med 0 0];          % acceleratia [m/s^2]

v     = v_kmh/3.6;                    % [m/s]
alfa  = atan(p/100);                  % rel. (18)
F_ra  = 0.5*rho*Cx*S*v.^2;            % rel. (7)
F_f   = f*M*g*cos(alfa);              % rel. (14)
G_t   = M*g*sin(alfa);                % rel. (17)
F_i   = delta*M*a;                    % rel. (22)/(23)
F_t   = F_ra + F_f + G_t + F_i;       % rel. (25)/(26)
T_w   = F_t*r_w;                      % rel. (31)/(46)
P_w   = F_t.*v;                       % rel. (28)/(47)
P_m   = P_w/eta;                      % rel. (29)
T_m   = F_t*r_w/(i_g*eta);            % rel. (33)
n_m   = v/(2*pi*r_w)*60*i_g;          % turatia motoarelor [rot/min]
F_z   = M*g*cos(alfa);                % rel. (37)
F_adh = mu*F_z;                       % rel. (35)
mu_nec = F_t./F_z;                    % din rel. (36)

F_drive0 = T_max*i_g*eta/r_w;         % forta la roti limitata de cuplu, rel. (6)
F_drive  = F_drive0*ones(size(v));
k = v > 0;
F_drive(k) = min(F_drive0, eta*P_vf./v(k));   % rel. (40)
F_tmax = min(F_drive, F_adh);         % rel. (42)
ok     = F_tmax >= F_t;               % rel. (43)

fprintf('r_w = %.4f m, i_g = %.3f, M = %d kg\n\n', r_w, i_g, M);
fprintf('%-28s %8s %9s %9s %8s %8s %8s %9s %6s %9s %9s %s\n', 'Regim', 'v[km/h]', 'F_t[N]', ...
        'T_w[Nm]', 'P_w[kW]', 'P_m[kW]', 'T_m[Nm]', 'n_m[rpm]', 'mu_nec', 'F_tmax[N]', 'F_drv[N]', 'Cond.(43)');
for j = 1:numel(v)
  if ok(j), c = 'DA'; else, c = 'NU'; end
  fprintf('%-28s %8.1f %9.1f %9.1f %8.2f %8.2f %8.1f %9.0f %6.3f %9.1f %9.1f %s\n', nume{j}, v_kmh(j), ...
          F_t(j), T_w(j), P_w(j)/1e3, P_m(j)/1e3, T_m(j), n_m(j), mu_nec(j), F_tmax(j), F_drive(j), c);
end

%% 3. Indicatori derivati
a_max0   = (mu - f)*g/delta;                       % acceleratia maxima la pornire (aderenta)
p_adh    = (mu - f)*100;                           % panta maxima, limita de aderenta [%]
vmaxP    = @(P) max(real(roots([0.5*rho*Cx*S 0 f*M*g -eta*P])));   % 1/2 rho Cx S v^3 + f M g v = eta P
v_cont   = vmaxP(P_cont)*3.6;
v_vf     = vmaxP(P_vf)*3.6;
fprintf('\na_max la pornire (mu=%.2f): %.3f m/s^2\n', mu, a_max0);
fprintf('Panta maxima (aderenta): %.1f %%\n', p_adh);
fprintf('v_max teoretic: %.1f km/h cu P_cont, %.1f km/h cu P_varf\n', v_cont, v_vf);

%% 4. Caracteristica de tractiune si timpul de accelerare
vk  = 0:5:300;                 % [km/h]
vv  = vk/3.6;                  % [m/s]
Fra = 0.5*rho*Cx*S*vv.^2;
Frez0  = Fra + f*M*g;
Frez10 = Fra + M*g*(f*cos(atan(p_1/100)) + sin(atan(p_1/100)));
Fdrv_vf   = F_drive0*ones(size(vv));  Fdrv_vf(2:end)   = min(F_drive0, eta*P_vf./vv(2:end));
Fdrv_cont = F_drive0*ones(size(vv));  Fdrv_cont(2:end) = min(F_drive0, eta*P_cont./vv(2:end));
Fmax_us   = min(Fdrv_vf, mu*M*g);
Fmax_perf = min(Fdrv_vf, mu_perf*M*g);
a_us   = (Fmax_us   - Frez0)/(delta*M);
a_perf = (Fmax_perf - Frez0)/(delta*M);
t_us   = [0 cumsum(diff(vv)./((a_us(1:end-1)   + a_us(2:end))/2))];     % metoda trapezelor
t_perf = [0 cumsum(diff(vv)./((a_perf(1:end-1) + a_perf(2:end))/2))];
fprintf('t 0-100: %.3f s (mu=%.2f), %.3f s (mu=%.2f); oficial %.1f s\n', t_us(vk==100), mu, ...
        t_perf(vk==100), mu_perf, t_acc);
fprintf('t 0-200: %.3f s (mu=%.2f); oficial %.1f s\n', t_perf(vk==200), mu_perf, t_200);

%% 5. Grafice
fig1 = figure('Name', 'Caracteristica de tractiune');
plot(vk, Frez0, vk, Frez10, vk, Fdrv_vf, vk, Fdrv_cont, vk, mu*M*g*ones(size(vk)), '--', ...
     vk, mu_perf*M*g*ones(size(vk)), '--', 'LineWidth', 1.5);
grid on; xlabel('v [km/h]'); ylabel('F [N]'); ylim([0 35000]);
title('GT 63 4-Door Coupe - forte la roti');
legend('F_{rez} orizontal', 'F_{rez} rampa 10%', 'F_{t,drive} varf (860 kW)', ...
       'F_{t,drive} continuu (530 kW)', '\mu F_z (\mu=0,85)', '\mu F_z (\mu=1,20)', 'Location', 'northeast');
print(fig1, '-dpng', '-r120', 'fig_forte_tractiune.png');

fig2 = figure('Name', 'Puteri');
plot(vk, Frez0.*vv/eta/1e3, vk, Frez10.*vv/eta/1e3, vk, P_vf/1e3*ones(size(vk)), '--', ...
     vk, P_cont/1e3*ones(size(vk)), '--', 'LineWidth', 1.5);
grid on; xlabel('v [km/h]'); ylabel('P_m [kW]'); ylim([0 900]);
title('Puterea ceruta motoarelor la viteza constanta');
legend('drum orizontal', 'rampa 10%', 'P_{varf} = 860 kW', 'P_{cont} = 530 kW', 'Location', 'northwest');
print(fig2, '-dpng', '-r120', 'fig_puteri.png');

fig3 = figure('Name', 'Accelerare');
plot(t_us, vk, t_perf, vk, 'LineWidth', 1.5); hold on;
plot([t_acc t_200], [100 200], 'ko', 'MarkerFaceColor', 'k');
grid on; xlabel('t [s]'); ylabel('v [km/h]'); xlim([0 15]);
title('Accelerare din loc (model) vs. date oficiale');
legend('\mu = 0,85 (asfalt uscat)', '\mu = 1,20 (anvelope performanta)', 'oficial 0-100 / 0-200', 'Location', 'southeast');
print(fig3, '-dpng', '-r120', 'fig_accelerare.png');
