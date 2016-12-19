classdef SkinModel < handle & dynamicprops
%--------------------------------------------------------------------------
% Generate Skin Model from original binary STL file.
%   Following the sequance of the methods:
%   1. Read
%   2. Seg
%   3. Sim deviation
%   4. Comb
%   5. Export
%--------------------------------------------------------------------------
% Read before using:
%   1. If it's the first time simulate for a model, use the tyical process.
%   2. Segmentation works well only for:
%       1> Part with sharp and acute face connection
%       2> Size of each feature shold be similar
%   3. Once segmentation are done and the result is satisfying, save the
%      instance of the model, thus the numbering of surfaces after seg are
%      fixed, and don't need to seg it again the next time.
%   4. Specify manufacturing deviations by methods:
%       1> TR--translation
%       2> RO--rotation
%       3> MD--generate mode and scaled
%   5. All deviations are considered as displacement boundary conditions,
%      and solving by FEA & Penalty Function Approach.
%   6. 'ResetD'--To generate a new skin model, use this method to set
%      manufacturing deviation to zero. Not necessary to reload model.
%--------------------------------------------------------------------------

    
    properties
        % These properties are for the original model.
        % Vertice cordinates of original model, each row corrosponding x,y,z (before segmentation)
        V;
        % Number of Vertices inside a triangle, each row is a triangle (before segmentation)
        T;
        % Other segmentation properties are saved as dynamic properties.
        % Number of surfaces after segmentation
        N_Surf;

        % Table of parameters for deviation simulation
        DivTable={};
    end
    
    properties(Hidden)
        % Normal vector for each triangle
        N;
        % Vertice normal, which is calculated by the mean value of its one-disc triangles
        VN;
        
        % Basic Properties for FEA combination
        % Generated during segmentation
        ELM;
        % Stiffness matrix
        K;
        C;
        % Deviation vectors, contains deviation for each vertex
        D;
        % Large value used for penalty function approach
        S=1e17;
        
        % Skin Model parameters
        % The generated skin model instance
        SM;
        
        % DP is a vector to save the dynamic property that added, and used
        % when do the segmentation again, but not delete the whole model
        DP;
    end
    
    methods
        
        % Read original STL file.
        function Read( Obj, filename )
            
            % Open the file, assumes STL Binary format.
            fid=fopen( filename, 'r');
            if fid == -1
                error('File could not be opened, please check name or path!')
            end
            
            % Read file title and number of facets
            ftitle=fread(fid,80,'uchar=>schar');
            num_facet=fread(fid,1,'int32');
            
            % Pre-allocate memory to save running time
            Obj.V=zeros(3*num_facet,3);
            Obj.T=zeros(num_facet,3);
            Obj.N=zeros(num_facet,3);
            col=uint16(0);
            for i=1:num_facet,
                Obj.N(i,1)=fread(fid,1,'float32');
                Obj.N(i,2)=fread(fid,1,'float32');
                Obj.N(i,3)=fread(fid,1,'float32');
                Obj.V(3*(i-1)+1,1)=fread(fid,1,'float32');
                Obj.V(3*(i-1)+1,2)=fread(fid,1,'float32');
                Obj.V(3*(i-1)+1,3)=fread(fid,1,'float32');
                Obj.V(3*(i-1)+2,1)=fread(fid,1,'float32');
                Obj.V(3*(i-1)+2,2)=fread(fid,1,'float32');
                Obj.V(3*(i-1)+2,3)=fread(fid,1,'float32');
                Obj.V(3*(i-1)+3,1)=fread(fid,1,'float32');
                Obj.V(3*(i-1)+3,2)=fread(fid,1,'float32');
                Obj.V(3*(i-1)+3,3)=fread(fid,1,'float32');
                Obj.T(i,1)=3*(i-1)+1;
                Obj.T(i,2)=3*(i-1)+2;
                Obj.T(i,3)=3*(i-1)+3;
                col=fread(fid,1,'uint16');
            end
            fclose(fid);
            
            % Delet the duplicated vertices
            % re-link the number in Obj.T to new Obj.V
            [Obj.V, ~, indexn] =  unique(Obj.V, 'rows');
            Obj.T = indexn(Obj.T);
            
            % Re-calculate the normal of triangles
            e1=Obj.V(Obj.T(:,2),:)-Obj.V(Obj.T(:,1),:);
            e2=Obj.V(Obj.T(:,3),:)-Obj.V(Obj.T(:,2),:);
            Obj.N=cross(e1,e2);
            for i=1:size(Obj.N,1)
                Obj.N(i,:)=Obj.N(i,:)/norm(Obj.N(i,:));
            end
            
            % Calculate normal of vertices
            Obj.V(:,4)=linspace(1,size(Obj.V,1),size(Obj.V,1)); % Need this number
            Obj.VN=zeros(size(Obj.V,1),3);
            for i=1:size(Obj.V,1)
                [r,~]=find(Obj.T(:,1:3)==Obj.V(i,4));
                N_used=Obj.N(r,1:3);
                VN_sum=[sum(N_used(:,1)),sum(N_used(:,2)),sum(N_used(:,3))];
                VN_i=VN_sum/norm(VN_sum);
                Obj.VN(i,:)=VN_i;
            end
            Obj.V(:,4)=[];
            
        end
        
        % Segment model into 'N_Surf' patches, using first 'N_Mode' modes
        function Seg( Obj, N_Mode, N_Surf )
            % Check and clean former segmentation result
            if ~isempty(Obj.N_Surf)
                for i=1:Obj.N_Surf
                    delete(Obj.DP(i)); % Delet segmented surfaces, which is a dynamic property
                end
            end
            Obj.DP=[];
            
            Obj.N_Surf=N_Surf;
            
            % Calculation of the mesh edge
            EG=zeros(size(Obj.V,1),size(Obj.V,1));
            for i=1:size(Obj.T,1)
                n1=Obj.T(i,1);
                n2=Obj.T(i,2);
                n3=Obj.T(i,3);
                
                if EG(n1,n2)==0
                    EG(n1,n2)=i;
                else
                    EG(n2,n1)=i;
                end
                
                if EG(n2,n3)==0
                    EG(n2,n3)=i;
                else
                    EG(n3,n2)=i;
                end
                
                if EG(n3,n1)==0
                    EG(n3,n1)=i;
                else
                    EG(n1,n3)=i;
                end
            end
            EV=[];
            ET=[];
            for i=1:size(EG,1)-1
                for j=i:size(EG,1)
                    if EG(i,j)~=0
                        EV=[EV;i,j];
                        ET=[ET;EG(i,j),EG(j,i)];
                    end
                end
            end
            
          % Use EV to generate ELM, reduced the same calculation
            Obj.ELM=EV;
            Obj.ELM=sort(Obj.ELM,2);
            Obj.ELM=unique(Obj.ELM,'rows');
            
            % Non-closed surface mesh will have edges on the boundary
            mark=[];
            for i=1:size(ET,1)
                if (ET(i,1)==0)||(ET(i,2)==0)
                    mark=[mark;i];
                end
            end
            EV(mark,:)=[];
            ET(mark,:)=[];
            
            % Calculation of the modes
            n_e=size(ET,1);
            DIF=zeros(n_e,1);
            for i=1:n_e
                DIF(i,1)=(norm(Obj.N(ET(i,1),1:3)-Obj.N(ET(i,2),1:3)))^2;% This is important part, and need to improve !
            end
            if mean(DIF)>0.001
                DIF=DIF/mean(DIF);
            end
            W=zeros(n_e,1);
            for i=1:n_e
                W(i,1)=norm(Obj.V(EV(i,1),:)-Obj.V(EV(i,2),:))*exp(-DIF(i,1));
            end
            n_t=size(Obj.T,1);
            L=sparse(n_t,n_t);
            L2=sparse(n_t,n_t);
            for i=1:n_e
                L(ET(i,1),ET(i,2))=W(i,1);
            end
            L=L+L';
            for i=1:n_t
                L2(i,i)=sum(L(i,:));
            end
            L=L2-L;
            %             opts.issym = 1;
            %             [Veig,~]=eigs(L,NUM+1,'SM',opts);
            [Veig,~]=eigs(L,N_Mode,'SM');
            Veig=fliplr(Veig);
            
            % Clustering
            n=size(Veig,2);
            for i=1:n
                a=min(Veig(:,i));
                b=max(Veig(:,i));
                Veig(:,i)=(Veig(:,i)-a)/(b-a);
            end
            ID=kmeans(Veig,N_Surf);% ID is the surface number for triangles
            
            Obj.V(:,4)=linspace(1,size(Obj.V,1),size(Obj.V,1));
            Obj.T(:,4)=linspace(1,size(Obj.T,1),size(Obj.T,1));
            Obj.N(:,4)=linspace(1,size(Obj.N,1),size(Obj.N,1));
            
            for i=1:N_Surf
                name=['SF',num2str(i)];
                Obj.DP=[Obj.DP;Obj.addprop(name)];
                Obj.(name).F=find(ID==i);
                Obj.(name).T=Obj.T(Obj.(name).F,:);
                V_used=unique(Obj.(name).T(:,1:3));
                Obj.(name).V=Obj.V(V_used,:);
                Obj.(name).N=Obj.N(Obj.(name).F,:);
                Obj.(name).VN=zeros(size(Obj.(name).V,1),4);
                for j=1:size(Obj.(name).V,1)
                    [r,~]=find(Obj.(name).T(:,1:3)==Obj.(name).V(j,4));
                    N_used=Obj.(name).N(r,1:3);
                    VN_sum=[sum(N_used(:,1)),sum(N_used(:,2)),sum(N_used(:,3))];
                    VN=VN_sum/norm(VN_sum);
                    Obj.(name).VN(j,:)=[VN,Obj.(name).V(j,4)];
                end
                % 'D' is for the deviation of each vertices
                Obj.(name).D=zeros(size(Obj.(name).V,1),1);
            end
            
            Obj.V(:,4)=[];
            Obj.T(:,4)=[];
            Obj.N(:,4)=[];
            
        end
        
        % If the segmentation reult is not good, pick one surface and segment again
        function ReSeg(Obj, id_SubSurf, N_Mode, N_Surf )
            
            if N_Surf<2
                error('Number of segmented surfaces should be large than one !')
            end
            
            % The idea of ReSeg is to creat a new SkinModel, segment it,
            % and copy the result back.
            name=['SF',num2str(id_SubSurf)];
            N_SM=SkinModel;
            N_SM.V=Obj.(name).V;
            N_SM.T=Obj.(name).T(:,1:3);
            N_SM.N=Obj.(name).N(:,1:3);
            N_SM.VN=Obj.(name).VN(:,1:3);
            
            for i=1:size(N_SM.T,1)
                for j=1:3
                    N_SM.T(i,j)=find(N_SM.V(:,4)==N_SM.T(i,j));
                end
            end
            N_SM.V(:,4)=[];
            
            N_SM.Seg(N_Mode, N_Surf);
            
            % Regenerate the index according to the global index
            N_SM.V(:,4)=Obj.(name).V(:,4);
            N_SM.T(:,4)=Obj.(name).T(:,4);
            N_SM.N(:,4)=Obj.(name).N(:,4);
            N_SM.VN(:,4)=Obj.(name).VN(:,4);
            for i=1:N_Surf
                name2=['SF',num2str(i)];
                for j=1:size(N_SM.(name2).F,1)
                    N_SM.(name2).F(j)=Obj.(name).T(N_SM.(name2).F(j),4);
                end
                for j=1:size(N_SM.(name2).T,1)
                    N_SM.(name2).T(j,4)=N_SM.T(N_SM.(name2).T(j,4),4);
                    for k=1:3
                        N_SM.(name2).T(j,k)=N_SM.V(N_SM.(name2).T(j,k),4);
                    end
                end
                N_SM.(name2).N(:,4)=N_SM.(name2).T(:,4);
                for j=1:size(N_SM.(name2).V,1)
                    N_SM.(name2).V(j,4)=N_SM.V(N_SM.(name2).V(j,4),4);
                end
                N_SM.(name2).VN(:,4)=N_SM.(name2).V(:,4);
            end
            
            % Put the segmentation result to original Skin Model
            i=1;
            name2=['SF',num2str(i)];
            Obj.(name)=N_SM.(name2);
            for i=2:N_Surf
                name=['SF',num2str(Obj.N_Surf+i-1)];
                name2=['SF',num2str(i)];
                Obj.DP=[Obj.DP;Obj.addprop(name)];
                Obj.(name)=N_SM.(name2);
            end
            Obj.N_Surf=Obj.N_Surf+N_Surf-1;
            
        end
        
        % Combination of deviations and nominal model
        function Comb( Obj, Scale )
            
            % ELM is generated during segmentation
            
            % K is generated, if it is empty
            if isempty(Obj.K)
                E=2.95e11;
                A=0.0001;
                nv=size(Obj.V,1);
                Obj.K=sparse(3*nv,3*nv);
                for n1=1:size(Obj.ELM,1)
                    a=Obj.ELM(n1,1);
                    b=Obj.ELM(n1,2);
                    node1=Obj.V(a,1:3);
                    node2=Obj.V(b,1:3);
                    %--------------------------------------------------------------------------
                    L=norm(node2-node1);
                    cos1=(node2(1)-node1(1))/L;
                    cos2=(node2(2)-node1(2))/L;
                    cos3=(node2(3)-node1(3))/L;
                    T=[cos1,cos2,cos3,0,0,0;0,0,0,cos1,cos2,cos3];
                    kk=E*A/L*(T')*[1,-1;-1,1]*T;
                    %--------------------------------------------------------------------------
                    DOF(1)=3*a-2;
                    DOF(2)=3*a-1;
                    DOF(3)=3*a;
                    DOF(4)=3*b-2;
                    DOF(5)=3*b-1;
                    DOF(6)=3*b;
                    for n2=1:6
                        for n3=1:6
                            Obj.K(DOF(n2),DOF(n3))= Obj.K(DOF(n2),DOF(n3))+kk(n2,n3);
                        end
                    end
                end
            end
            
            % C is generated, if it is empty
            nv=size(Obj.V,1);
            if isempty(Obj.C)
                mark=0;
                for i=1:Obj.N_Surf
                    name=['SF',num2str(i)];
                    Obj.(name).C=sparse(size(Obj.(name).VN,1),3*nv);
                    for j=1:size(Obj.(name).VN,1)
                        Obj.(name).C(j,(3*Obj.(name).VN(j,4)-2):3*Obj.(name).VN(j,4))=Obj.(name).VN(j,1:3);
                    end
                    mark=mark+j;
                end
                
                Obj.C=sparse(mark,3*nv);
                mark1=1;
                for i=1:Obj.N_Surf
                    name=['SF',num2str(i)];
                    mark2=size(Obj.(name).V,1);
                    Obj.C(mark1:(mark1+mark2-1),:)=Obj.(name).C;
                    mark1=mark1+mark2;
                end
            end
            
            % Get and Scale deviation matrix 'D'
            Obj.D=zeros(size(Obj.C,1),1);
            mark1=1;
            for i=1:Obj.N_Surf
                name=['SF',num2str(i)];
                mark2=size(Obj.(name).V,1);
                Obj.D(mark1:(mark1+mark2-1),1)=Obj.(name).D;
                mark1=mark1+mark2;
            end
            Obj.D=Scale*Obj.D;
            
            % FEA, 'SM' is the Skin Model
            Obj.SM.K=Obj.K+Obj.S*(Obj.C')*Obj.C;
            Obj.SM.P=Obj.S*(Obj.C')*Obj.D;
            Obj.SM.U=Obj.SM.K\Obj.SM.P;
            Obj.SM.V=Obj.V;
            for i=1:size(Obj.SM.V,1)
                Obj.SM.V(i,1:3)=Obj.SM.V(i,1:3)+Obj.SM.U((3*i-2):(3*i))';
                Obj.SM.CL(i,1)=dot(Obj.VN(i,1:3),Obj.SM.U((3*i-2):(3*i))');
            end
            
        end
        
        % Translate the feature, 'value' is a row vector
        function TR( Obj, id, value )
            name=['SF',num2str(id)];
            for i=1:size(Obj.(name).VN,1)
                Obj.(name).D(i,1)=dot(Obj.(name).VN(i,1:3),value);
            end
        end
        
        % Rotate the feature, 'value' is a row vector, in degree
        function RO( Obj, id, value )
            value=deg2rad(value);
            name=['SF',num2str(id)];
            ct=mean(Obj.(name).V(:,1:3));
            Rx=[1,0,0;
                0,cos(value(1)),-sin(value(1));
                0,sin(value(1)),cos(value(1))];
            Ry=[cos(value(2)),0,-sin(value(2));
                0,1,0;
                sin(value(2)),0,cos(value(2))];
            Rz=[cos(value(3)),-sin(value(3)),0;
                sin(value(3)),cos(value(3)),0;
                0,0,1;];
            for i=1:size(Obj.(name).V,1)
                d=(Rz*Ry*Rx*(Obj.(name).V(i,1:3)-ct)')'-(Obj.(name).V(i,1:3)-ct);
                Obj.(name).D(i,1)=dot(Obj.(name).VN(i,1:3),d);
            end
        end
        
        % Form error sim, using modes
        function MD(Obj, id_surf, id_mode, scale)
            name=['SF',num2str(id_surf)];
            
            % Calculation of the edge information
            EG=zeros(size(Obj.(name).V,1),size(Obj.(name).V,1));
            for i=1:size(Obj.(name).T,1)
                n1=find(Obj.(name).V(:,4)==Obj.(name).T(i,1));
                n2=find(Obj.(name).V(:,4)==Obj.(name).T(i,2));
                n3=find(Obj.(name).V(:,4)==Obj.(name).T(i,3));
                
                if EG(n1,n2)==0
                    EG(n1,n2)=i;
                else
                    EG(n2,n1)=i;
                end
                
                if EG(n2,n3)==0
                    EG(n2,n3)=i;
                else
                    EG(n3,n2)=i;
                end
                
                if EG(n3,n1)==0
                    EG(n3,n1)=i;
                else
                    EG(n1,n3)=i;
                end
            end
            EV=[];
            ET=[];
            for i=1:size(EG,1)-1
                for j=i:size(EG,1)
                    if EG(i,j)~=0
                        EV=[EV;i,j];
                        ET=[ET;EG(i,j),EG(j,i)];
                    end
                end
            end
            
            % Calculation of the modes
            n_e=size(EV,1);
            W=zeros(n_e,1);
            for i=1:n_e
                % Laplacian
                W(i,1)=norm(Obj.(name).V(EV(i,1),1:3)-Obj.(name).V(EV(i,2),1:3));
            end
            % Scaled the weight to [0,3], thus the calculation not influenced by the size of the model.
            W=4*W/max(W);
            % 'exp' reduced the problem on the boundary, and the result is better
            W=exp(-W);
            n_v=size(Obj.(name).V,1);
            L=zeros(n_v,n_v);
            L2=zeros(n_v,n_v);
            for i=1:n_e
                L(EV(i,1),EV(i,2))=W(i,1);
            end
            L=L+L';
            for i=1:n_v
                L2(i,i)=sum(L(i,:));
            end
            L=L2-L;
            L=sparse(L);
            [Veig,~]=eigs(L,id_mode,'SM');
            Veig=Veig(:,1);

            % Normalize and scale the mode
            m=max(abs(Veig));
            Veig=Veig/m*0.5;
            Obj.(name).D=zeros(size(Obj.(name).V,1),1);
            Obj.(name).D=Obj.(name).D+Veig*scale; % This is to combin with other deviaitons
            
            % Show the mode simulated, and deviation is amplified 10 times.
%             Color=zeros(size(Obj.V,1),1);
%             Div=zeros(size(Obj.V,1),3);
%             for i=1:size(Obj.(name).V,1)
%                 Color(Obj.(name).V(i,4),1)=Veig(i,1);
%                 % 'Div' is only for the current modal, not the combination
%                 Div(Obj.(name).V(i,4),1:3)=Obj.(name).VN(i,1:3)*Veig(i,1)*scale*10;
%             end
%             figure
%             trisurf(Obj.(name).T(:,1:3),Obj.V(:,1)+Div(:,1),Obj.V(:,2)+Div(:,2),Obj.V(:,3)+Div(:,3),Color,'FaceColor','Interp');
%             colormap jet
%             axis equal
%             axis off
        end
        
        % Generate DivTable for deviation simulation
        function GetDivTable(Obj)
            if isempty(Obj.N_Surf)
                error('Please segment the surface first, or set the number of surfaces to be one!')
            end
            Obj.DivTable=cell(Obj.N_Surf+1,4);
            % Surface: Number of corresponding surface
            % Translation: [x,y,z,mean,deviation]
            %       1>if [x,y,z] it is [0,0,0], generate random
            %           direction based on mean and deviation
            %       2>if vector is empty, skip
            % Rotation: [x,y,z,mean,deviation], similar to translation
            % Modal: [m1,m2,m3...,mean,deviaiton]
            %       1>m1,m2,m3... are the modes used
            %       2>their weights are generated randomly based on mean
            %           and deviation
            Obj.DivTable(1,:)={'Surface','Translation','Rotation','Modal'};
            Obj.DivTable(2,:)={'No.','[x,y,z,mean,dev]','[x,y,z,mean,dev]','[m1,m2,m3...,mean,dev]'};
            for i=1:Obj.N_Surf
                Obj.DivTable(i+2,1)={i};
            end
        end
        
        % Simulation based on parameters in DivTalbe
        function DivSim(Obj)
            if isempty(Obj.DivTable)
                error('Please generate DivTable, and specify simulation parameters!')
            end
            
            for i=1:Obj.N_Surf
                % Translation
                if ~isempty(Obj.DivTable{i+2,2})    % if not empty, simulate deviation
                    if Obj.DivTable{i+2,2}(1:3)==[0,0,0]    % if all zero, normal distribution in all direction
                        div=random('Normal',Obj.DivTable{i+2,2}(4),Obj.DivTable{i+2,2}(5),[1,3]);
                        Obj.TR(i,div);
                    else
                        dir=Obj.DivTable{i+2,2}(1:3);   % Direction specified for translation
                        dir=dir/norm(dir);
                        div=random('Normal',Obj.DivTable{i+2,2}(4),Obj.DivTable{i+2,2}(5));
                        Obj.TR(i,dir*div);
                    end
                end
                % Rotation
                if ~isempty(Obj.DivTable{i+2,3})    % if not empty, simulate rotation
                    if Obj.DivTable{i+2,3}(1:3)==[0,0,0]    % if all zero, normal distribution in all direction
                        div=random('Normal',Obj.DivTable{i+2,3}(4),Obj.DivTable{i+2,3}(5),[1,3]);
                        Obj.RO(i,div);
                    else
                        dir=Obj.DivTable{i+2,3}(1:3);   % Direction of axis specified for rotation
                        dir=dir/norm(dir);
                        div=random('Normal',Obj.DivTable{i+2,3}(4),Obj.DivTable{i+2,3}(5));
                        Obj.RO(i,dir*div);
                    end
                end
                % Modal
                if ~isempty(Obj.DivTable{i+2,4})    % if not empty, calculate modes
                    if size(Obj.DivTable{i+2,4},2)<=2   % Number of parameters should be bigger than 2
                        error('Not enough parameters for modal simulation, please check!')
                    else
                        num_m=size(Obj.DivTable{i+2,4},2)-2;    %Number of modes
                        div=random('Normal',Obj.DivTable{i+2,4}(num_m+1),Obj.DivTable{i+2,4}(num_m+2),[1,num_m]);
                        for j=1:num_m
                            Obj.MD(i,Obj.DivTable{i+2,4}(j),div(j));     %Combine modal deviaiton
                        end
                    end
                end
            end
            
        end
        
        % Reset the deviation value, to simulate new ones
        function ResetD( Obj )
            for i=1:Obj.N_Surf
                name=['SF',num2str(i)];
                Obj.(name).D=zeros(size(Obj.(name).V,1),1);
            end
        end
        
        % Plot original model
        function ShowOrg( Obj )
            figure
            map=trisurf(Obj.T,Obj.V(:,1),Obj.V(:,2),Obj.V(:,3));
            set(map,'FaceColor',[1,1,1]);
            axis equal
            axis off
        end
        
        % Plot segmented model
        function ShowSeg( Obj , id )
            % If want show all features, no input
            % If want to show certain surface, input its id (number)
            if nargin==1
                figure
                for i=1:Obj.N_Surf
                    name=['SF',num2str(i)];
                    center=mean(Obj.(name).V(:,1:3));
                    map=trisurf(Obj.(name).T(:,1:3),Obj.V(:,1),Obj.V(:,2),Obj.V(:,3));
                    set(map,'FaceColor',rand(1,3),'EdgeColor','non');
                    alpha(0.6);
                    text(center(1),center(2),center(3),num2str(i),'Color','red','FontSize',25);
                    hold on
                end
            elseif nargin==2
                name=['SF',num2str(id)];
                map=trisurf(Obj.(name).T(:,1:3),Obj.V(:,1),Obj.V(:,2),Obj.V(:,3));
                set(map,'FaceColor',rand(1,3));
                hold on
            end
            axis equal
            axis off
        end
        
        % Plot generated Skin Model
        function ShowSM( Obj )
            figure
            trisurf(Obj.T,Obj.SM.V(:,1),Obj.SM.V(:,2),Obj.SM.V(:,3),Obj.SM.CL,'FaceColor','Interp');
            colormap jet
            axis equal
            axis off
        end
        
    end
    
end

