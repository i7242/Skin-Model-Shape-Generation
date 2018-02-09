<!DOCTYPE html
  PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html><head>
      <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
   <!--
This HTML was auto-generated from MATLAB code.
To make changes, update the MATLAB code and republish this document.
      --><title>Skin Model Generation Process</title><meta name="generator" content="MATLAB 8.6"><link rel="schema.DC" href="http://purl.org/dc/elements/1.1/"><meta name="DC.date" content="2018-02-09"><meta name="DC.source" content="Guide.m"><style type="text/css">
html,body,div,span,applet,object,iframe,h1,h2,h3,h4,h5,h6,p,blockquote,pre,a,abbr,acronym,address,big,cite,code,del,dfn,em,font,img,ins,kbd,q,s,samp,small,strike,strong,sub,sup,tt,var,b,u,i,center,dl,dt,dd,ol,ul,li,fieldset,form,label,legend,table,caption,tbody,tfoot,thead,tr,th,td{margin:0;padding:0;border:0;outline:0;font-size:100%;vertical-align:baseline;background:transparent}body{line-height:1}ol,ul{list-style:none}blockquote,q{quotes:none}blockquote:before,blockquote:after,q:before,q:after{content:'';content:none}:focus{outine:0}ins{text-decoration:none}del{text-decoration:line-through}table{border-collapse:collapse;border-spacing:0}

html { min-height:100%; margin-bottom:1px; }
html body { height:100%; margin:0px; font-family:Arial, Helvetica, sans-serif; font-size:10px; color:#000; line-height:140%; background:#fff none; overflow-y:scroll; }
html body td { vertical-align:top; text-align:left; }

h1 { padding:0px; margin:0px 0px 25px; font-family:Arial, Helvetica, sans-serif; font-size:1.5em; color:#d55000; line-height:100%; font-weight:normal; }
h2 { padding:0px; margin:0px 0px 8px; font-family:Arial, Helvetica, sans-serif; font-size:1.2em; color:#000; font-weight:bold; line-height:140%; border-bottom:1px solid #d6d4d4; display:block; }
h3 { padding:0px; margin:0px 0px 5px; font-family:Arial, Helvetica, sans-serif; font-size:1.1em; color:#000; font-weight:bold; line-height:140%; }

a { color:#005fce; text-decoration:none; }
a:hover { color:#005fce; text-decoration:underline; }
a:visited { color:#004aa0; text-decoration:none; }

p { padding:0px; margin:0px 0px 20px; }
img { padding:0px; margin:0px 0px 20px; border:none; }
p img, pre img, tt img, li img, h1 img, h2 img { margin-bottom:0px; } 

ul { padding:0px; margin:0px 0px 20px 23px; list-style:square; }
ul li { padding:0px; margin:0px 0px 7px 0px; }
ul li ul { padding:5px 0px 0px; margin:0px 0px 7px 23px; }
ul li ol li { list-style:decimal; }
ol { padding:0px; margin:0px 0px 20px 0px; list-style:decimal; }
ol li { padding:0px; margin:0px 0px 7px 23px; list-style-type:decimal; }
ol li ol { padding:5px 0px 0px; margin:0px 0px 7px 0px; }
ol li ol li { list-style-type:lower-alpha; }
ol li ul { padding-top:7px; }
ol li ul li { list-style:square; }

.content { font-size:1.2em; line-height:140%; padding: 20px; }

pre, code { font-size:12px; }
tt { font-size: 1.2em; }
pre { margin:0px 0px 20px; }
pre.codeinput { padding:10px; border:1px solid #d3d3d3; background:#f7f7f7; }
pre.codeoutput { padding:10px 11px; margin:0px 0px 20px; color:#4c4c4c; }
pre.error { color:red; }

@media print { pre.codeinput, pre.codeoutput { word-wrap:break-word; width:100%; } }

span.keyword { color:#0000FF }
span.comment { color:#228B22 }
span.string { color:#A020F0 }
span.untermstring { color:#B20000 }
span.syscmd { color:#B28C00 }

.footer { width:auto; padding:10px 0px; margin:25px 0px 0px; border-top:1px dotted #878787; font-size:0.8em; line-height:140%; font-style:italic; color:#878787; text-align:left; float:none; }
.footer p { margin:0px; }
.footer a { color:#878787; }
.footer a:hover { color:#878787; text-decoration:underline; }
.footer a:visited { color:#878787; }

table th { padding:7px 5px; text-align:left; vertical-align:middle; border: 1px solid #d6d4d4; font-weight:bold; }
table td { padding:7px 5px; text-align:left; vertical-align:top; border:1px solid #d6d4d4; }

  </style></head><body><div class="content">
#  **Skin Model Generation Process** 
<!--introduction--><!--/introduction-->
## Contents
<div>
* [Acknowledgement](#1)* [1 Creat Instance](#2)* [2 Read STL Model](#3)* [3 Segment Model into "K" Surfaces](#6)* [4 Simulate Manufacturing Deviations for Each Surface](#13)* [5 Solving the Combination by FEA](#19)* [6 Use of 'ResetD'](#23)* [7 Export Skin Model Shape in STL File](#24)
</div>
## Acknowledgement<a name="1"></a>

This work was conducted at Institut de M&eacute;canique et d'Ing&eacute;nierie (I2M), Universit&eacute; de Bordeaux. Please cite the following article when using:

Xingyu Yan, Alex Ballu. Generation of consistent skin model shape based on FEA method. Int J Adv Manuf Technol 2017. doi:10.1007/s00170-017-0177-5.

[http://link.springer.com/10.1007/s00170-017-0177-5](http://link.springer.com/10.1007/s00170-017-0177-5)

## 1 Creat Instance<a name="2"></a>

To creat the instance of skin model, using method as below. The instance "M" contains no data initially.
<pre class="codeinput">M=SkinModel;
</pre>
## 2 Read STL Model<a name="3"></a>

The STL file should be puted in current work folder, or sub-folders. The name is a string ending with ".stl". The format should be binary.

Using "Read" method to read the STL file, and put data into "M".
<pre class="codeinput">M.Read(<span class="string">'Test_Nominal_Model.stl'</span>);
</pre>
There are two properties inside the instance "M":
<div>
1. "V": n*3 vertices matrix. "n" is the number of vertices, 3 column corresponding to x, y, z coordinates2. "T": m*3 triangle matrix. "m" is the number of triangles, 3 column corresponding to the row number of 3 vertices in "V" matrix.
</div>
Using "ShowOrg" to plot the original model, which is usually considered as nominal model.
<pre class="codeinput">M.ShowOrg;
</pre><img vspace="5" hspace="5" src="Guide_01.png" alt=""> 
## 3 Segment Model into "K" Surfaces<a name="6"></a>

The segmentation uses spectral based method:
<div>
1. At first, a matrix contains topological and geometrical information was constructed.2. Then the eigenvectors correspond to the the first "N" largest "N" eigenvalues are calculated.   The value of "N" is the first input of method "Seg".3. Using "K-means" clastering algorithm and the "N" eigenvectors,   the entrances in the eigenvectors are clastered. This corresponds   to the segmentation of the model surfaces. "K" is the number of   surfaces, which is the second input of method "Seg".
</div>
In simple application, we can assume the number of eigenvectors "N" is the same as the number of surfaces "K". For test model, we set both value as "8"
<pre class="codeinput">M.Seg(8,8);
</pre>
After segmentation, "K" surface properties are added. For "SF(i)", it is a struct data. It contains several fields:
<div>
1. "F": the index of trangles inside this surface.2. "T": n*4 matrix, the trangles of this surface. The first 3 column is the  vertices index, the 4-th column is the triangle index in matrix before segmentation.3. "V": m*4 matrix, the vertices in this surface. The first 3 column is its coordinates, the 4-th column is its index in matrix before segmentation.4. "N": normal vector of triangles.5. "VN": normal vector of vertices. Estimated based on "N".6. "D": deviation vector. Save the deviation value of vertex along normal direction.
</div>
After segmentation, we can plot the segmentation result using "ShowSeg" method.
<pre class="codeinput">M.ShowSeg;
</pre><img vspace="5" hspace="5" src="Guide_02.png" alt=""> 
Additionally, we can plot the numbering of each surface.
<pre class="codeinput">M.ShowSegNum;
</pre><img vspace="5" hspace="5" src="Guide_03.png" alt=""> 
If the segmentation result is not acceptable, we may have two choices:
<div>
1. Clean the skin model instance "M", change parameter "N" and "K", do       the segmentation again. This is for the segmentation result is too       far from expectation.2. Using methods like "Reseg" and "Union" to modify the segmentation       result. This is used when little modification could achive better result.
</div>
Once the segmentation of the nominal model is done, the user is suggested to save the current instance variable "M" into hard disc, Such as:
<pre class="codeinput"><span class="comment">% save M_after_seg M</span>
</pre>
In next time, user can load the model after segmentation directly:
<pre class="codeinput"><span class="comment">% load M_after_seg</span>
</pre>
This is to avoid conduct segmentation process each time. Meanwhile, because the segmentation result is saved, users can define deviation simulation parameters for each surface, and simulate a batch of skin model shapes.

## 4 Simulate Manufacturing Deviations for Each Surface<a name="13"></a>

To simulate manufacturing deviations, two types of process can be applied:
<div>
1. Using methods to assign deviation type and value for single feature directly.2. Using deviation parameter table to simulat defects for all surfaces.
</div>
**4.1 "TR", "RO" &amp; "MD"**

In the first approach, methods such as "TR", "RO" and "MD" can be used.

Method "TR" indicates "Translation". The first input "id" indicates which surface will be translated. The second input "value" is a vector, which defines the translation value along "x", "y" and "z" axis.
<pre class="codeinput"><span class="comment">% M.TR(id,value)</span>
</pre>
Method "RO" indicates "Rotation". The first input is the surface "id". The second input the the degree of rotation along "x", "y" and "z" axis. Notice it is in degree, not in radian.
<pre class="codeinput"><span class="comment">% M.RO(id,value)</span>
</pre>
Method "MD" indicates "Modes". The first input is the surface "id", the second input "id_mode" is the numbering of mode (eigenvector). Because the eigenvector is normalized, the third input "scale" is used to control the maximum deviation value.
<pre class="codeinput"><span class="comment">% M.MD(id_surf, id_mode, scale)</span>
</pre>
**4.2 "DivTable"**

In the second approach, we can define a table, which contains deviation information(which is the inputs in the first approach). Then using the "DivSim" method, form defects are simulated according to the table we have defined. The "DivSim" method actually calls methods "TR", "RO" and "MD".

To use the "DivTable", we first initialise it by "GetDivTable" method.
<pre class="codeinput">M.GetDivTable;
</pre>
Then we can find "DivTable" property in the skin model instance "M". It is a table containing surface information and deviation information.
<div>
1. The first row of the table is deviation type (Translation, Rotation, and Modal).2. The first colunm of the table is the numbering of surfaces.3. By editing corresponding parameters, we can define different type of deviations for different surfaces.
</div>
For different types of deviations:
<div>
1. Translation: [x,y,z,mean,dev]. The first 3 variable is the translation direction vector. The magnitude of translation is generated by random parameter following Normal distribution. The "mean" and "dev" are mean value and standard deviation value for this distribution.2. Rotation: [x,y,z,mean,dev]. The first 3 variable is the rotation axis vector. The magnitude of rotation is generated by random parameter following Normal distribution. The "mean" and "dev" are mean value and standard deviation value for this distribution.3. Modal: [m1,m2,m3,......,mean,dev]. The first several variables indicates the modes used for simulation. The scales(coefficients) of the modes are generated following the Normal distribution. "mean" and "dev" are parameters for the Normal distribution. (The number of modes are not limited, but if used, at least one)
</div>
For each type of defect, if we left the entrance in the table empty, corresponding defects will not be simulated.

To edit the table, we can edit it in the workspace, or load a pre-defined table. Here we load and use the "Table" defined before.
<pre class="codeinput">load <span class="string">Table</span>
M.DivTable=Table;
</pre>
Method "DivSim" will simulate the deviation according to the table.
<pre class="codeinput">M.DivSim;
</pre>
## 5 Solving the Combination by FEA<a name="19"></a>

The combination of the deviation value and nominal model are based on FEA. More details can be found in:

Xingyu Yan, Alex Ballu. Generation of consistent skin model shape based on FEA method. Int J Adv Manuf Technol 2017. doi:10.1007/s00170-017-0177-5.

[http://link.springer.com/10.1007/s00170-017-0177-5](http://link.springer.com/10.1007/s00170-017-0177-5)

The input "1" is a scale value, which could be used to amplify the defects. In default, we set it "1".
<pre class="codeinput">M.Comb(1);
</pre>
Properties for FEA, and the generated skin model shape, are hiden properties, which does not need to be modified.

After combination, the skin model shape could be shown by method "ShowSM".
<pre class="codeinput">M.ShowSM;
</pre><img vspace="5" hspace="5" src="Guide_04.png" alt=""> 
The user is suggested to save the instance once they have conducted the first time of combination(using "Comb"). This is because some data for conduct FEA will be saved. Reloading of these data will avoid unnecessary calculation.
<pre class="codeinput"><span class="comment">% save M_after_comb M</span>

<span class="comment">% load M_after_comb</span>
</pre>
## 6 Use of 'ResetD'<a name="23"></a>

In some cases, we may not generate the desired form defects directly, and we may want to conduct the simulation again. Using "ResetD" method, we can erase the defects we have simulated, and conduct the simulation again from section **4 Simulate Manufacturing Deviations for Each Surface**.

This avoided the clear and reload of the model.
<pre class="codeinput">M.ResetD;
</pre>
## 7 Export Skin Model Shape in STL File<a name="24"></a>

The generated skin model shape could be expoeted as STL file. Input is the file name ending with ".stl".
<pre class="codeinput">M.ExportSTL(<span class="string">'Test_Skin_Model_Shape.stl'</span>)
</pre><p class="footer">  
[Published with MATLAB&reg; R2015b](http://www.mathworks.com/products/matlab/)  

</div><!--
##### SOURCE BEGIN #####
%% *Skin Model Generation Process*
%
%% Acknowledgement
% This work was conducted at Institut de Mécanique et d'Ingénierie (I2M),
% Université de Bordeaux.
% Please cite the following article when using:
%
% Xingyu Yan, Alex Ballu. Generation of consistent skin model shape based on FEA method. Int J Adv Manuf Technol 2017. doi:10.1007/s00170-017-0177-5.
%
% <http://link.springer.com/10.1007/s00170-017-0177-5>
%

%% 1 Creat Instance
% To creat the instance of skin model, using method as below.
% The instance "M" contains no data initially.
M=SkinModel;

%% 2 Read STL Model
% The STL file should be puted in current work folder, or sub-folders.
% The name is a string ending with ".stl".
% The format should be binary.
%
% Using "Read" method to read the STL file, and put data into "M".
M.Read('Test_Nominal_Model.stl');

%%
% There are two properties inside the instance "M":
%
% # "V": n*3 vertices matrix. "n" is the number of vertices, 3 column corresponding
% to x, y, z coordinates
% # "T": m*3 triangle matrix. "m" is the number of triangles, 3 column
% corresponding to the row number of 3 vertices in "V" matrix.
%

%%
% Using "ShowOrg" to plot the original model, which is usually considered as
% nominal model.
M.ShowOrg;

%% 3 Segment Model into "K" Surfaces
% The segmentation uses spectral based method:
%
% # At first, a matrix contains topological and geometrical information was constructed.
% # Then the eigenvectors correspond to the the first "N" largest "N" eigenvalues are calculated.
%   The value of "N" is the first input of method "Seg".
% # Using "K-means" clastering algorithm and the "N" eigenvectors,
%   the entrances in the eigenvectors are clastered. This corresponds
%   to the segmentation of the model surfaces. "K" is the number of
%   surfaces, which is the second input of method "Seg".
%
% In simple application, we can assume the number of eigenvectors "N" is
% the same as the number of surfaces "K".
% For test model, we set both value as "8"
M.Seg(8,8);

%%
% After segmentation, "K" surface properties are added.
% For "SF(i)", it is a struct data. It contains several fields:
%
% # "F": the index of trangles inside this surface.
% # "T": n*4 matrix, the trangles of this surface. The first 3 column is
% the  vertices index, the 4-th column is the triangle index in matrix before
% segmentation.
% # "V": m*4 matrix, the vertices in this surface. The first 3 column is
% its coordinates, the 4-th column is its index in matrix before
% segmentation.
% # "N": normal vector of triangles.
% # "VN": normal vector of vertices. Estimated based on "N".
% # "D": deviation vector. Save the deviation value of vertex along normal
% direction.
%

%%
% After segmentation, we can plot the segmentation result using "ShowSeg" method.
M.ShowSeg;

%%
% Additionally, we can plot the numbering of each surface.
M.ShowSegNum;

%%
% If the segmentation result is not acceptable, we may have two choices:
%
% # Clean the skin model instance "M", change parameter "N" and "K", do
%       the segmentation again. This is for the segmentation result is too
%       far from expectation.
% # Using methods like "Reseg" and "Union" to modify the segmentation
%       result. This is used when little modification could achive better result.
%
% Once the segmentation of the nominal model is done, the user is suggested
% to save the current instance variable "M" into hard disc, Such as:

% save M_after_seg M

%%
% In next time, user can load the model after segmentation directly:

% load M_after_seg

%%
% This is to avoid conduct segmentation process each time. Meanwhile,
% because the segmentation result is saved, users can define deviation
% simulation parameters for each surface, and simulate a batch of skin
% model shapes.

%% 4 Simulate Manufacturing Deviations for Each Surface
% To simulate manufacturing deviations, two types of process can be applied:
%
% # Using methods to assign deviation type and value for single feature directly.
% # Using deviation parameter table to simulat defects for all surfaces.
%
% *4.1 "TR", "RO" & "MD"*
%
% In the first approach, methods such as "TR", "RO" and "MD" can be used.
%
% Method "TR" indicates "Translation". The first input "id" indicates which
% surface will be translated. The second input "value" is a vector, which
% defines the translation value along "x", "y" and "z" axis.

% M.TR(id,value)

%%
% Method "RO" indicates "Rotation". The first input is the surface "id".
% The second input the the degree of rotation along "x", "y" and "z" axis.
% Notice it is in degree, not in radian.

% M.RO(id,value)

%%
% Method "MD" indicates "Modes". The first input is the surface "id", the
% second input "id_mode" is the numbering of mode (eigenvector). Because the
% eigenvector is normalized, the third input "scale" is used to control the
% maximum deviation value.

% M.MD(id_surf, id_mode, scale)

%%
% *4.2 "DivTable"*
%
% In the second approach, we can define a table, which contains deviation
% information(which is the inputs in the first approach). Then using the
% "DivSim" method, form defects are simulated according to the table we have defined.
% The "DivSim" method actually calls methods "TR", "RO" and "MD".
%
% To use the "DivTable", we first initialise it by "GetDivTable" method.
M.GetDivTable;

%%
% Then we can find "DivTable" property in the skin model instance "M".
% It is a table containing surface information and deviation information.
%
% # The first row of the table is deviation type (Translation,
% Rotation, and Modal).
% # The first colunm of the table is the numbering of surfaces.
% # By editing corresponding parameters, we can define different type of
% deviations for different surfaces.
%
% For different types of deviations:
%
% # Translation: [x,y,z,mean,dev]. The first 3 variable is the translation direction vector.
% The magnitude of translation is generated by random parameter following Normal distribution.
% The "mean" and "dev" are mean value and standard deviation value for this distribution.
% # Rotation: [x,y,z,mean,dev]. The first 3 variable is the rotation axis vector.
% The magnitude of rotation is generated by random parameter following Normal distribution.
% The "mean" and "dev" are mean value and standard deviation value for this distribution.
% # Modal: [m1,m2,m3,......,mean,dev]. The first several variables
% indicates the modes used for simulation. The scales(coefficients) of the
% modes are generated following the Normal distribution. "mean" and "dev"
% are parameters for the Normal distribution.
% (The number of modes are not limited, but if used, at least one)
%
% For each type of defect, if we left the entrance in the table empty,
% corresponding defects will not be simulated.
%
% To edit the table, we can edit it in the workspace, or load a pre-defined
% table. Here we load and use the "Table" defined before.
load Table
M.DivTable=Table;

%%
% Method "DivSim" will simulate the deviation according to the table.
M.DivSim;

%% 5 Solving the Combination by FEA
% The combination of the deviation value and nominal model are based on
% FEA. More details can be found in:
%
% Xingyu Yan, Alex Ballu. Generation of consistent skin model shape based on FEA method. Int J Adv Manuf Technol 2017. doi:10.1007/s00170-017-0177-5.
%
% <http://link.springer.com/10.1007/s00170-017-0177-5>
%
% The input "1" is a scale value, which could be used to amplify the
% defects. In default, we set it "1".
M.Comb(1);

%%
% Properties for FEA, and the generated skin model shape, are hiden
% properties, which does not need to be modified.

%%
% After combination, the skin model shape could be shown by method
% "ShowSM".
M.ShowSM;

%%
% The user is suggested to save the instance once they have conducted the
% first time of combination(using "Comb").
% This is because some data for conduct FEA will be saved. Reloading of
% these data will avoid unnecessary calculation.

% save M_after_comb M

% load M_after_comb

%% 6 Use of 'ResetD'
%
% In some cases, we may not generate the desired form defects directly, and
% we may want to conduct the simulation again. Using "ResetD" method, we
% can erase the defects we have simulated, and conduct the simulation again from
% section *4 Simulate Manufacturing Deviations for Each Surface*.
%
% This avoided the clear and reload of the model.

M.ResetD;

%% 7 Export Skin Model Shape in STL File
% The generated skin model shape could be expoeted as STL file.
% Input is the file name ending with ".stl".
M.ExportSTL('Test_Skin_Model_Shape.stl')

##### SOURCE END #####
--></body></html>
