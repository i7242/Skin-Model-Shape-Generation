%% Skin Model Generation Process
close all
clear
clc

%% 1 Creat instance
M=SkinModel;

%% 2 Read STL model
M.Read('PT01.stl');
M.ShowOrg;

%% 3 Segment model into N surfaces
% 12,9,10,14
M.Seg(9,9);
M.ShowSeg;

%% 4 Get the Deviation Table 'DivTable' for simulation
M.GetDivTable;

%% 5 Edit parameters in 'DivTable'
load PT03_Table
M.DivTable=Table;

%% 6 Simulate for each surfaces
M.DivSim;

%% 7 Solving the Combination by FEA with Penalty Function Approach
M.Comb(0);
M.ShowSM;

%% 8 Use 'ResetD' to set deviation to zero, not delet the model and generate new one
M.ResetD;

%% 9 After generated skin model shape, export it to a FeatureGroup in GeoSpelling
M.Export('PT01');

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


