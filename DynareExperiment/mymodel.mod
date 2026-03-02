%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SIMPLE RBC MODEL — BK-CONDITION SATISFIED
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
@#define BETA  = 0.99
@#define ALPHA = 0.36
@#define DELTA = 0.025
@#define RHO   = 0.95
@#define SIGMA = 0.01
@#define PHI   = 1.0

var c k y i n a;
varexo e;

parameters beta alpha delta rho sigma phi;

% --------------------------------------------------
% Parameter
% --------------------------------------------------
beta  = @{BETA};     % Diskontfaktor
alpha = @{ALPHA};     % Kapitalelastizität
delta = @{DELTA};    % Abschreibung
rho   = @{RHO};     % AR(1) Persistenz
sigma = @{SIGMA};     % Schock-Skalierung
phi   = @{PHI};      % Arbeitsdisutilität

% --------------------------------------------------
% Modell
% --------------------------------------------------
model;

    % Produktion (Kapital ist vorgegeben!)
    y = exp(a) * k(-1)^alpha * n^(1-alpha);

    % Ressourcenrestriktion
    y = c + i;

    % Kapitalakkumulation
    k = (1-delta)*k(-1) + i;

    % Euler-Gleichung (KORREKTES TIMING!)
    1/c = beta * (1/c(+1)) * ( alpha*y(+1)/k(+1) + 1 - delta );

    % Arbeitsangebotsbedingung (statisch!)
    phi * n / (1-n) = (1-alpha) * y / c;

    % Technologieprozess
    a = rho*a(-1) + sigma*e;

end;

% --------------------------------------------------
% Startwerte
% --------------------------------------------------
initval;
    a = 0;
    n = 0.33;
    k = 10;
    y = k^alpha * n^(1-alpha);
    i = delta*k;
    c = y - i;
end;

% --------------------------------------------------
% Lösung & Simulation
% --------------------------------------------------
steady;
check;

shocks;
    var e;
    stderr 1;
end;

stoch_simul(order=1, irf=20);
