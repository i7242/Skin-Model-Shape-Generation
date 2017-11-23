%% Skin Model Generation Process
close all
clear
clc

%% 1 Creat instance
M=SkinModel;

%% 2 Read STL model
M.Read('PT03.stl');
M.ShowOrg;

%% 3 Segment model into N surfaces
% 12,9,10,14
M.Seg(14,14);
M.ShowSeg;

%% 4 Get the Deviation Table 'DivTable' for simulation
M.GetDivTable;

%% 5 Edit parameters in 'DivTable'
load PT03_Table
M.DivTable=Table;

%%
for i=1:20
    %% 6 Simulate for each surfaces
    M.DivSim;
    
    %% 7 Solving the Combination by FEA with Penalty Function Approach
    M.Comb(1);
    
    %% 9 After generated skin model shape, export it to a FeatureGroup in GeoSpelling
    M.Export('PT03');
    
    %%
    name=['PT03_',num2str(i)];
    save(name,'PT03');
    
    %% 8 Use 'ResetD' to set deviation to zero, not delet the model and generate new one
    M.ResetD;
    
end

load handel
sound(y,Fs)

%% Save M, to use in next time

% save M M

%% Reload the model used before
% This is because each time the numbering of segmentation result is
% changing. To specify the surface I already konw, a model is saved in
% advance and reload here.
% Also, after Comb, the stiffness matrix K is already calculated. Reload
% will save time for calculation

% load M;

%% Simulate deviations for each surfaces
% It is possible to specify deviation for certain feature manually
% For more infomation, looking at the code

% M.RO(6,[3,3,0]);
% M.TR(3,[0,3,3]);
% M.MD(2,5,3);


