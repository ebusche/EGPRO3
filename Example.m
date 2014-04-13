% Example of how to use the BuildPyramid function
% set image_dir and data_dir to your actual directories
image_dir = 'scene_categories(1)'; 
data_dir = 'data3';
newfolder = 'testFolder3';

%put all images in one folder relabeled.
categories = labelImages( image_dir , newfolder);
% for other parameters, see BuildPyramid

fnames = dir(fullfile(newfolder, '*.jpg'));
num_files = size(fnames,1);
filenames = cell(num_files,1);
labels = zeros(num_files,1);


for f = 1:num_files
	filenames{f} = fnames(f).name;

    %record category label
    for i = 1: size(categories, 1)
        if(strcmp(filenames{f}(end - 7: end -4), categories{i}))
            labels(f) = i;
            i = size(categories, 1);
            
        end
    end
end

%control all the parameters
%params.maxImageSize = 1000
%params.gridSpacing = 1
%params.patchSize = 16
params.dictionarySize = 200;
params.numTextonImages = 100 *(size(categories) -2);
params.pyramidLevels = 2;
pyramid_all = BuildPyramid(filenames,newfolder,[data_dir],params,1);


SVMclass('data3\pyramids_all_200_2.mat', labels, params.numTextonImages);
% compute histogram intersection kernel
%K = hist_isect(pyramid_all, pyramid_all); 

% for faster performance, compile and use hist_isect_c:
% K = hist_isect_c(pyramid_all, pyramid_all);
