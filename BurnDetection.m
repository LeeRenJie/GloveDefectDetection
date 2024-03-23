tp05                            %---------------Detect Burn Holes----------------%
% Load the image
image = imread('Burn-1.jpg');

% Convert to grayscale
grayImage = rgb2gray(image);

% Convert the grayscale image to a binary image using adaptive thresholding
% Convert to binary helps to identify regions of interest
binary = imbinarize(grayImage, 'adaptive', 'ForegroundPolarity','dark','Sensitivity',0.4);

% Perform morphological opening to remove noise 
% This involves erosion followed by dilation, using a disk-shaped structuring element.
structuringElement = strel('disk', 17);
cleanedImage = imopen(binary, structuringElement);

% Label connected components in binary Image
[connectedComponents, numberOfObjects] = bwlabel(cleanedImage);

% Extract properties of the connected components, focusing on their area, pixel indices, 
% and centroids
stats = regionprops(connectedComponents, 'Area', 'PixelIdxList', 'Centroid');

% Sort the connected components based on their area in descending order
[sortedAreas, sortedIdx] = sort([stats.Area], 'descend');

% Initialize a binary mask to highlight burn holes within the objects
holeMask = false(size(grayImage));

% Iterate over the sorted connected components, starting from the second largest
% The largest component is likely not a hole but the main object of interest
for k = 2:length(sortedAreas)
    % Define a threshold for what we consider a bunr hole
    % This threshold can be defined based on the size of the holes we expect to find
    holeAreaThreshold = 100;
    
    % If the area of the current component exceeds the threshold, it's marked as a hole
    if stats(sortedIdx(k)).Area > holeAreaThreshold
        % Update the burn hole mask to include the current component
        holeMask(stats(sortedIdx(k)).PixelIdxList) = true;
    end
end

% Find the boundary of the identified holes for visualization
[B, L] = bwboundaries(holeMask, 'noholes');

% Start plotting
figure;

% Subplot for the original image
subplot(2, 2, 1);
imshow(image);
title('Original Image');

% Subplot for the binary image
subplot(2, 2, 2);
imshow(binary);
title('Binary Image');

% Subplot for the cleaned image
subplot(2, 2, 3);
imshow(cleanedImage);
title('Cleaned Image');

% Subplot for the original image with boundaries of the holes
subplot(2, 2, 4);
imshow(image);
hold on;
title('Original Image with Hole Boundaries');

% Overlay the boundaries of the holes of identified holes on the image
for k = 1:length(B)
    boundary = B{k};
    plot(boundary(:,2), boundary(:,1), 'r', 'LineWidth', 2);
end
hold off;

