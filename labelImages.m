function [categories] = labelImages( folder , newfolder)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here


files = dir([folder, '/*']);
mkdir(newfolder);

categories = cell(5); %cell(size(files));
for i = 1: 5 %size(files)
    
    if(~strcmp(files(i).name, '.') && ~strcmp(files(i).name, '..'))
        
        imagepath = [folder '/' files(i).name];
        images = dir([imagepath, '/*.JPG']);
        suffix = files(i).name(1:4);
        categories{i} = suffix;
       
        for j = 1: size(images);
           % files(i).name
            %images(j).name
            orgImage = [folder '/' files(i).name '/' images(j).name];
            newImage = [newfolder '/' images(j).name(1:end-4) suffix '.jpg'];
            copyfile(orgImage,newImage);
            
        end
    end
end

