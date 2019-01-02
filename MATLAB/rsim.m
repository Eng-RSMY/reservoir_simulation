%% define geometry
lm = 20;
h = 100;
lf = 0.1;
wr = 0.05;
g = geomet(lm, h, lf, wr);
%% create PDE model
reservoir = createpde(1); % 1 - m , 2 - f
geometryFromEdges(reservoir,g); % geometryFromEdges for 2-D
%%
pdegplot(reservoir,'EdgeLabels','on');
%% generate mesh
mesh = generateMesh(reservoir,'Hmax',50,'Hmin',0.05);
% view mesh
pdemesh(reservoir)
%% specify coefficients, boundary conditions, and initial conditions
% coefficients
s = get_parameters;
coefm = specifyCoefficients(reservoir,'m',0,...
                           'd',@dcoeffunctionm,...
                           'c',@ccoeffunctionm,...
                           'a',0,...
                           'f',@fcoeffunctionm,...
                           'Face',[1:2:21,22:2:42]);
coeff = specifyCoefficients(reservoir,'m',0,...
                           'd',@dcoeffunctionf,...
                           'c',@ccoeffunctionf,...
                           'a',0,...
                           'f',@fcoeffunctionf,...
                           'Face',[2:2:20,23:2:41]);
% boundary conditions
bc_w = applyBoundaryCondition(reservoir,...
    'dirichlet', 'Edge', [48:2:66,69:2:87], 'u', s.Pi);
    %'dirichlet', 'Edge', [48:2:66,69:2:87], 'u', s.Pi);
bc_b = applyBoundaryCondition(reservoir,...
    'neumann', 'Edge', [1:46,47:2:67,68:2:88], 'g', [0], 'q', [0]);
%%
% initial conditions
ic = setInitialConditions(reservoir,s.Pi);
%% set tlist
tlist = [0:100];
%%
initial_conditions = solvepde(reservoir,tlist);
%%
ui = initial_conditions.NodalSolution;
pdeplot(reservoir,'XYData',ui(:,101),'FaceAlpha',0.5)
xlim([0 220])
ylim([0 100])
colormap gray
%%
% boundary conditions
bc_w = applyBoundaryCondition(reservoir,...
    'dirichlet', 'Edge', [48:2:66,69:2:87], 'u', s.Pwf);
days = 10000;
tlist = [1:86400:((86400*days))];
ic = setInitialConditions(reservoir,initial_conditions);
%% solve pde
simulation_results = solvepde(reservoir,tlist);
%% get solution
u = simulation_results.NodalSolution;
%% plot solution
day = 10000;
figure
pdeplot(reservoir,'XYData',u(:,day),'FaceAlpha',0.5)
xlim([0 220])
ylim([0 100])
%%
load('lengths.mat');
days = [0,1,10,500,1000,10000];

ca = [];
cf = [];
ct = [];
% loop through days
for day = days
    % loop through matrix regions
    cfm = 0;
    cam = 0;
    for i = 1:11
        x = [mat_l(i,1):.5:mat_l(i,2)];
        y = [0:0.05,49.95,50.05:.5:100];
        [X,Y] = meshgrid(x,y);
        if day == 0
            uintrp = ones(size(X)).*s.Pi;
        else

            uintrp = interpolateSolution(simulation_results,X,Y,day);
            if any([any(uintrp == 0),any(isnan(uintrp)),any(uintrp == inf)]) 
                nandata = uintrp;
                xdata=(1:length(nandata))';
                uintrp = interp1(xdata(~isnan(nandata)),nandata(~isnan(nandata)),xdata);
            end
        end
        p = reshape(uintrp,size(X));   
        cfma = s.phim.*rho_mahmood(p,s.T,s.Pc,s.Tc);
        cama = (1-s.phim).*s.rhos.*langmuir(p,s.PL,s.VL);
        cfms = trapz(y,trapz(x,cfma,2));
        cams = trapz(y,trapz(x,cama,2));
        cfm = cfm + cfms;
        cam = cam + cams;
    end
    % loop through fracture regions
    cff = 0;
    for i = 1:10
        x = [mat_l(i,1):.5:mat_l(i,2)];
        y = [0:0.05,49.95,50.05:.5:100];
        [X,Y] = meshgrid(x,y);
        if day == 0
            uintrp = ones(size(X)).*s.Pi;
        else
            uintrp = interpolateSolution(simulation_results,X,Y,day);
        end
        p = reshape(uintrp,size(X));
        cffa = s.phif.*rho_mahmood(p,s.T,s.Pc,s.Tc);
        cff = trapz(y,trapz(x,cffa,2));
    end
    ca = [ca, cam];
    cf = [cf, cfm+cff];
    ct = [ct, cam+cfm+cff];
end
figure
plot(days,ct)
title('total')
figure
plot(days,ca)
title('adsorbed')
figure
plot(days,cf)
title('free')
%%

[X,Y] = meshgrid([20:.05:20.1],[50.05:.5:100]);
[X,Y] = meshgrid([0:.5:20],[50.05:.5:100]);
%%
x = [0:.5:20];
y = [0:0.5:49.95,50.5:.5:100];
[X,Y] = meshgrid(x,y);
day = 1000;
uintrp = interpolateSolution(simulation_results,X,Y,day);
v = reshape(uintrp,size(X));
%%
figure
surf(X,Y,v,'LineStyle','none')
axis equal
view(0,90)
colorbar
%% integrate
I = trapz(y,trapz(x,v,2));