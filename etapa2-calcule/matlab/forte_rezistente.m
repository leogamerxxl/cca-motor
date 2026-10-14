function F = forte_rezistente(v, a, V, C)
%FORTE_REZISTENTE Forțele pe vehicul (suport P2, slide 5) pentru viteza v și accelerația a.
%   v poate fi scalar sau vector [m/s]; a [m/s^2]; V = date vehicul; C = constante().
%     Ff  = mu_f * M * g * cos(alpha)            frecare la rulare
%     Fra = 1/2 * rho * S * Cx * (v - Vv)^2      rezistență aerodinamică
%     Gt  = M * g * sin(alpha)                   componenta greutății pe pantă
%     Fi  = M * a                                forța de inerție
%     Ft  = Fra + Ff + Gt + M*a                  forța de tracțiune necesară
%     Fa  = mu_a * M * g * cos(alpha)            forța de aderență (limita Ft <= Fa)

F.Ff  = C.mu_f * V.M * C.g * cos(C.alpha) * ones(size(v));
F.Fra = 0.5 * C.rho * V.S * V.Cx * (v - C.Vv).^2;
F.Gt  = V.M * C.g * sin(C.alpha) * ones(size(v));
F.Fi  = V.M * a .* ones(size(v));
F.Ft  = F.Fra + F.Ff + F.Gt + F.Fi;
F.Fa  = C.mu_a * V.M * C.g * cos(C.alpha);
end
