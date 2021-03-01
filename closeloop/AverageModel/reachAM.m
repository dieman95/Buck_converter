% Reachability analysis of the average model
% Diego Manzanas, September 30th 2020
clc;clear;close all

%% Load Controller

load('final_model.mat'); % Load weights
layer1 = LayerS(W{1},b{1}','poslin'); % hidden layer #1
layer2 = LayerS(W{2},b{2}','poslin'); % hidden layer #2
layer3 = LayerS(W{3},b{3}','satlins'); % output layer (satlins)
layer4 = LayerS(0.5,0.5,'purelin'); % Normalization
Layers = [layer1 layer2 layer3 layer4];
Controller = FFNNS(Layers); % neural network controller

%% Load plant model

% Parameters
C = 4.4e-6; % capacitor value
L = 5e-5; % inductor value
R = 4; % resistor value
% T = 0.00001;% sample time
T = 1e-5;
Vs = 10;% input (source) voltage
Vref = 6;% reference voltage
% Tmax = 1000*(1/R*C);% max simulation time
D = Vref / Vs;% duty cycle        

% Define ss matrices
A_avg = [0, -(1/L); (1/C), -(1/(R*C))];% switch closed
B_avg = [Vs*(D/L); 0];
C = eye(2);
D = [0;0];

% Create plant
controlPeriod = T;
nSteps = 10;
reachStep = controlPeriod/nSteps;
Plant = LinearODE(A_avg, B_avg, C, D, controlPeriod,nSteps); % Linear ODE plant
plant_cora = LinearODE_cora(A_avg, B_avg, C, D, reachStep, controlPeriod); % LinearODE cora plant
nlPlant = NonLinearODE(2,1,@dynamicsAM,reachStep,controlPeriod,C); % Nonlinear ODE plant 


%% Define reachability parameters

N = 25; % Number of control steps to simulate the system

lb = [0;0];
ub = [0.5;0.5];

%% Simulation (MATLAB & CORA)

% Sim (CORA)
% n_sim = 100; % Number of simulations
n_sim = 25;
step_sim = N; % Number of simulation steps
X0s = lb'+rand(n_sim,2).*(ub'-lb'); % Set of random initial points to simulate
t = 0;
dT = T;
sim2 = zeros(n_sim,2,step_sim+1);
sim1 = zeros(n_sim,2,step_sim*nSteps);
for j=1:n_sim
    x0 = X0s(j,:)';
    sim2(j,:,1) = x0;
    for i=1:step_sim
        Vout = x0(2);
        inCont = [Vref - Vout;Vref;x0(1:2)];
        yC = Controller.evaluate(inCont);
        [tV,y] = plant_cora.evaluate(x0,yC);
        x0 = y(end,:)';
        x0a = y';
        t = t+dT;
        sim2(j,:,i+1) = x0;
        sim1(j,:,((i-1)*(nSteps)+1):i*nSteps+1) = x0a;
    end
end

%% Compare 1 step reachability (only involving plant models)
% Make sure the end result is the same for all of them
% First comparison (input = 0)
% 
% outC = Star(0,0);
% plantR1 = plant_cora; % Linear ode cora plant
% R1 = plantR1.stepReachStar(init_set,outC);
% R1a = plantR1.intermediate_reachSet;
% plantR2 = nlPlant; % nonliear ode cora plant
% R2 = plantR2.stepReachStar(init_set,outC);
% R2a = plantR2.intermediate_reachSet;
% plantR3 = Plant; % Linear ode NNV model
% R3 = plantR3.simReach('direct',init_set,outC,reachStep,nSteps);
% % Plot all sets
% figure;
% Star.plots(R1a,'r');
% title('Linear ODE (CORA)');
% figure;
% Star.plots(R2a,'m');
% title('Nonlinear ODE (CORA)')
% figure;
% Star.plots(R3,'b');
% title('Linear ODE (NNV)');
% % Plot last set (control period set)
% figure;
% Star.plots(R1,'r');
% title('Linear ODE (CORA)');
% figure;
% Star.plots(R2,'m'); % Exact method for this one fails sometimes
% title('Nonlinear ODE (CORA)')
% figure;
% Star.plots(R3(end),'b');
% title('Linear ODE (NNV)');
% % Plot approx. last set (control period set)
% figure;
% Star.plotBoxes_2D(R1,1,2,'r');
% title('Linear ODE (CORA)');
% figure;
% Star.plotBoxes_2D(R2,1,2,'m');
% title('Nonlinear ODE (CORA)')
% figure;
% Star.plotBoxes_2D(R3(end),1,2,'b');
% title('Linear ODE (NNV)');
% 
% % Second comparison (input = 1)
% 
% outC = Star(1,1);
% plantR1 = plant_cora; % Linear ode cora plant
% R1 = plantR1.stepReachStar(init_set,outC);
% R1a = plantR1.intermediate_reachSet;
% plantR2 = nlPlant; % nonliear ode cora plant
% R2 = plantR2.stepReachStar(init_set,outC);
% R2a = plantR2.intermediate_reachSet;
% plantR3 = Plant; % Linear ode NNV model
% R3 = plantR3.simReach('direct',init_set,outC,reachStep,nSteps);
% % Plot all sets
% figure;
% Star.plots(R1a,'r');
% title('Linear ODE (CORA)');
% figure;
% Star.plots(R2a,'m');
% title('Nonlinear ODE (CORA)')
% figure;
% Star.plots(R3,'b');
% title('Linear ODE (NNV)');
% % Plot last set (control period set)
% figure;
% Star.plots(R1,'r');
% title('Linear ODE (CORA)');
% figure;
% Star.plots(R2,'m'); % Exact method for this one fails sometimes
% title('Nonlinear ODE (CORA)')
% figure;
% Star.plots(R3(end),'b');
% title('Linear ODE (NNV)');
% % Plot approx. last set (control period set)
% figure;
% Star.plotBoxes_2D(R1,1,2,'r');
% title('Linear ODE (CORA)');
% figure;
% Star.plotBoxes_2D(R2,1,2,'m');
% title('Nonlinear ODE (CORA)')
% figure;
% Star.plotBoxes_2D(R3(end),1,2,'b');
% title('Linear ODE (NNV)');
% 
% % Third comparison (input = 0.1)
% 
% outC = Star(0.1,0.1);
% plantR1 = plant_cora; % Linear ode cora plant
% R1 = plantR1.stepReachStar(init_set,outC);
% R1a = plantR1.intermediate_reachSet;
% plantR2 = nlPlant; % nonliear ode cora plant
% R2 = plantR2.stepReachStar(init_set,outC);
% R2a = plantR2.intermediate_reachSet;
% plantR3 = Plant; % Linear ode NNV model
% R3 = plantR3.simReach('direct',init_set,outC,reachStep,nSteps);
% % Plot all sets
% figure;
% Star.plots(R1a,'r');
% title('Linear ODE (CORA)');
% figure;
% Star.plots(R2a,'m');
% title('Nonlinear ODE (CORA)')
% figure;
% Star.plots(R3,'b');
% title('Linear ODE (NNV)');
% % Plot last set (control period set)
% figure;
% Star.plots(R1,'r');
% title('Linear ODE (CORA)');
% figure;
% Star.plots(R2,'m'); % Exact method for this one fails sometimes
% title('Nonlinear ODE (CORA)')
% figure;
% Star.plots(R3(end),'b');
% title('Linear ODE (NNV)');
% % Plot approx. last set (control period set)
% figure;
% Star.plotBoxes_2D(R1,1,2,'r');
% title('Linear ODE (CORA)');
% figure;
% Star.plotBoxes_2D(R2,1,2,'m');
% title('Nonlinear ODE (CORA)')
% figure;
% Star.plotBoxes_2D(R3(end),1,2,'b');
% title('Linear ODE (NNV)');

%% Reachability analysis 1 (NNV, direct and approx-star NN)
disp(' ');
disp('---------------------------------------------------');
disp('Method 1 - NNV')
init_set = Star(lb,ub);
plant1 = Plant;
try
    reachSet_1 = [init_set];
    reachAll_1 = [init_set];
    for i=1:N
        inNN = input_to_Controller(Vref,init_set);
        outC = Controller.reach(inNN,'exact-star');
%         if outC.nVar > 1000
%             outC = outC.getBox;
%             outC = outC.toStar;
%         end
        outC = outC(1);
        init_set = plant1.simReach('direct', init_set, outC, reachStep, nSteps); % reduce the order (basic vectors) in order for the code to finish
        reachAll_1 = [reachAll_1 init_set];
        init_set = init_set(end);
        reachSet_1 = [reachSet_1 init_set];
        if init_set.nVar > 1000
            init_set = init_set.getBox;
            init_set = init_set.toStar;
        end
    end
catch e
    disp(' ');
    warning("Method 1 failed"); pause(0.01);
    fprintf(2,'THERE WAS AN ERROR. THE MESSAGE WAS:\n\n%s',getReport(e));
end
% This method is really not working well


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Reachability analysis 2 (CORA-standard, approx)
% disp(' ');
% disp('---------------------------------------------------');
% disp('Method 2 - CORA');
% init_set = Star(lb,ub);
% plant2 = plant_cora;
% try
%     reachSet_2 = [init_set];
%     for i=1:N
%         inNN = input_to_Controller(Vref,init_set);
%         outC = Controller.reach(inNN,'approx-star');
%         init_set = plant2.stepReachStar(init_set,outC);
% %         init_set = Star.get_convex_hull(init_set);
%         reachSet_2 = [reachSet_2 init_set];
%     end
% catch e
%     disp(' ');
%     warning("Method 2 failed"); pause(0.01);
%     fprintf(2,'THERE WAS AN ERROR. THE MESSAGE WAS:\n\n%s',getReport(e));
% end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Reachability analysis 3 (CORA-adap, approx)
% disp(' ');
% disp('---------------------------------------------------');
% disp('Method 3 - CORA');
% init_set = Star(lb,ub);
% plant3 = plant_cora;
% plant3.set_linAlg('adap');
% try
%     reachSet_3 = [init_set];
%     for i=1:N
%         inNN = input_to_Controller(Vref,init_set);
%         outC = Controller.reach(inNN,'approx-star');
%         init_set = plant3.stepReachStar(init_set,outC);
% %         init_set = Star.get_convex_hull(init_set);
%         reachSet_3 = [reachSet_3 init_set];
%     end
% catch e
%     disp(' ');
%     warning("Method 3 failed"); pause(0.01);
%     fprintf(2,'THERE WAS AN ERROR. THE MESSAGE WAS:\n\n%s',getReport(e));
% end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Reachability analysis 5 (NNV, direct, approx)
% disp(' ');
% disp('---------------------------------------------------');
% disp('Method 5 - NNV'); % Not really exact tho. Ranges estimmated in Plant.simReach (minkowski sum for plant reachability)
% init_set = Star(lb,ub1);
% plant5 = Plant;
% try
%     reachSet_5 = [init_set];
%     reachAll_5 = [init_set];
%     for i=1:N
%         inNN = input_to_Controller(Vref,init_set);
%         outC = Controller.reach(inNN,'approx-star');
%         if outC.nVar > 1000
%             outC = outC.getBox;
%             outC = outC.toStar;
%         end
%         init_set = plant5.simReach('direct',init_set,outC,reachStep,nSteps);
%         reachAll_5 = [reachAll_5 init_set];
%         init_set = init_set(end);
% %         init_set = Star.get_convex_hull(init_set);
%         reachSet_5 = [reachSet_5 init_set];
%         if init_set.nVar > 1000
%             init_set = init_set.getBox;
%             init_set = init_set.toStar;
%         end
%     end
% catch e
%     disp(' ');
%     warning('Method 5 failed'); pause(0.01);
%     fprintf(2,'THERE WAS AN ERROR. THE MESSAGE WAS:\n\n%s',getReport(e));
% end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Reachability analysis 6 (nonlinear)
% disp(' ');
% disp('---------------------------------------------------');
% disp('Method 6 - nonlinear')
% init_set = Star(lb,ub);
% try
%     reachSet_6 = [init_set];
%     for i=1:N
%         inNN = input_to_Controller(Vref,init_set);
%         outC = Controller.reach(inNN,'approx-star');
%         init_set = nlPlant.stepReachStar(init_set,outC);
%         reachSet_6 = [reachSet_6 init_set];
%     end
% catch e
%     disp(' ');
%     warning('Nonlinear method failed'); pause(0.01);
%     fprintf(2,'THERE WAS AN ERROR. THE MESSAGE WAS:\n\n%s',getReport(e));
% end




%% Visualize results

timeV = 0:reachStep:controlPeriod;
% Plot Reach Sets
f = figure;
hold on;
for p=1:n_sim
    simP = sim1(p,:,:);
    nl = size(simP,3);
    simP = reshape(simP,[dim, nl]);
    plot(simP(1,:),simP(2,:),'r');
end
Star.plotBoxes_2D_noFill(reachAll,1,2,'b');
xlabel('x_1')
ylabel('x_2');
title('Open Loop - MFAM (hw)');
saveas(f,'OpenLoop_MFAM_reach_hw.png');

% Plot reach sets vs time (Current)
f = figure;
hold on;
for p=1:n_sim
    simP = sim1(p,:,:);
    nl = size(simP,3);
    simP = reshape(simP,[dim, nl]);
    plot(timeV,simP(1,:),'r');
end
Star.plotRanges_2D(reachAll,1,timeV,'b');
xlabel('Time (seconds)')
ylabel('Current');
title('Open Loop - MFAM (hw)');
saveas(f,'OpenLoop_MFAM_reachI_hw.png');

% Plot reach sets vs time (Voltage)
f = figure;
hold on;
for p=1:n_sim
    simP = sim1(p,:,:);
    nl = size(simP,3);
    simP = reshape(simP,[dim, nl]);
    plot(timeV,simP(2,:),'r');
end
Star.plotRanges_2D(reachAll,2,timeV,'b');
xlabel('Time (seconds)')
ylabel('Voltage');
title('Open Loop - MFAM (hw)');
saveas(f,'OpenLoop_MFAM_reachV_hw.png');

f = figure;
hold on;
for p=1:n_sim
    simP = sim1(p,:,:);
    nl = size(simP,3);
    simP = reshape(simP,[2, nl]);
    plot(simP(1,:),simP(2,:),'r');
end
Star.plotBoxes_2D_noFill(reachAll_1,1,2,'b');
xlabel('x_1')
ylabel('x_2');
title('Average Model');
saveas(f,'AvgModel_reach.png');

%% Helper Functions

function inNN = input_to_Controller(Vref,init_set)
    l = length(init_set);
    inNN = [];
    for i = 1:l
        out1 = init_set(i).affineMap([0 1],-Vref); % input 1 (Vref - Vout)
        out1 = out1.affineMap(-eye(1),[]);
        out12 = out1.concatenate_with_vector(Vref); % input 1 + input 2
        out = out12.concatenate(init_set(i).affineMap([0 1;1 0],[])); % add inputs 3 and 4 (Vout,Iout)
        inNN = [inNN out];
    end
end