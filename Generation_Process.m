%% Skin Model Generation Process
close all
clear
clc

%% 1 Creat instance
M=SkinModel;

%% 2 Read STL model
M.Read('Test_Nominal_Model.stl');
M.ShowOrg;

%% 3 Segment model into N surfaces
M.Seg(8,8);
M.ShowSeg;

%% 4 Get the Deviation Table 'DivTable' for simulation
M.GetDivTable;

%% 5 Edit parameters in 'DivTable'
load Table
M.DivTable=Table;

%% 6 Simulate for each surfaces
M.DivSim;

%% 7 Solving the Combination by FEA with Penalty Function Approach
M.Comb(1);
M.ShowSM;

%% 8 Export Skin Model Shape
M.ExportSTL('Test_Skin_Model_Shape.stl')


