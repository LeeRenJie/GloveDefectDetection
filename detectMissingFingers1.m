function detectMissingFingers1(img)
% Convert the RGB image to the HSV color space for easier color segmentation
hsvImg = rgb2hsv(img);

% Define the HSV color range for detecting skin, which might include areas resembling missing fingers
% Note: These values may need to be adjusted based on the specific characteristics of the image
skinHueRange = [0.0 0.09]; % Range of hue for skin colors
skinSaturationRange = [0.3 0.7]; % Saturation range for skin
skinValueRange = [0.3 0.9]; % Value (brightness) range for skin

% Create a binary mask identifying skin areas within the defined HSV ranges
skinMask = (hsvImg(:,:,1) >= skinHueRange(1)) & (hsvImg(:,:,1) <= skinHueRange(2)) & ...
           (hsvImg(:,:,2) >= skinSaturationRange(1)) & (hsvImg(:,:,2) <= skinSaturationRange(2)) & ...
           (hsvImg(:,:,3) >= skinValueRange(1)) & (hsvImg(:,:,3) <= skinValueRange(2));

% Remove small objects from the mask that are unlikely to be parts of fingers
% This helps to reduce noise and isolate larger areas indicative of missing fingers
MissFingerMaskCleaned = bwareaopen(skinMask, 6300); % Threshold for object size might need adjustment

% Apply morphological closing to the mask to fill in gaps and connect nearby regions
% This helps in creating a more continuous area representing missing fingers
structuringElement = strel('disk', 100); % Disk-shaped structuring element for morphological operations
MissFingerMaskClosed = imclose(cleanedSkinMask, structuringElement);

% Display the result image
figure('units','normalized','outerposition',[0 0 1 1]);
subplot(1, 4, 1);
imshow(img);
title('Original Image');

subplot(1, 4, 2);
imshow(MissFingerMaskCleaned);
title('Missing Finger Mask Before Closing');

subplot(1, 4, 3);
imshow(MissFingerMaskClosed);
title('Missing Finger Mask After Closing');


% Analyze the closed mask to identify and characterize regions that might indicate missing fingers
connectedComponents = bwconncomp(closedSkinMask);
regionsStats = regionprops(connectedComponents, 'Area', 'Centroid', 'BoundingBox');

if isempty(regionsStats)
    disp('No Holes found');
else
    % Draw the circle on the original image for each defect
    subplot(1, 4, 4);
    imshow(img);
    hold on;
    title('Detected Missing Finger with Red Circles');
    
    %Factor determine the size of the circle
    visualizationIncreaseFactor = 1; 
    
     % Iterate through detected regions to visualize them
    for idx = 1:numel(stats)
        % Calculate visualization parameters based on region properties
        boundingBox = regionsStats(idx).BoundingBox;
        diameter = max(boundingBox(3), boundingBox(4)) * visualizationIncreaseFactor;
        radius = diameter / 2;
        centerPosition = regionsStats(idx).Centroid;

        % Draw the circle around the detected region
        viscircles(centerPosition, radius, 'Color', 'r', 'LineWidth', 1);
    end
    
    hold off;
    title('Detected Mising Finger with Red Circles');
end
end